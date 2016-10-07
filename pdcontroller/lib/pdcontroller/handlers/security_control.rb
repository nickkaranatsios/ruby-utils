require 'pp'

# This it to be implemented as follows
# There is a trasition conditon that says something like successful access on inside zone in Tamagawa plant
# We also check that there is a security control setting for the same access. 
# Then we send an EventAlarmAddRequest to adapter.
# Then we expect to receive an EventAlarmAddResponse and EventAlarmNotification
# If we receive both we need to send SecurityControlActionRequest to adapter
# We suppose to send an EventAlarm with workorderid set to 0.
# When we transition we suppose to send an EventAlarm with workorderid set to a proper work order
#
class SecurityControlAddRequest < Message
  def parse_message(message, params)
    session = params[:session]
    security_control_id = message["id"]
    pa_request_id = message['request_id']
    dest_pa = session.find(DEST_PA)

    begin
      security_control = SecurityControl.find(security_control_id) or raise "Failed to read a security control #{security_control_id} from db"
#{"message_class":"EventAlarmAddRequest","id":4164609635,"work_order_id":1,"worker":{"trait":[{"card_id":"card1234","face_id":"face1234"},{"card_id":"card5678","face_id":"face5678"}]},"request_id":"3c63072b0a31e2d109419bdd386f2de6985daa92468059c052c6edb32dc500de","event_alarm":"successful access on outside zone in Tamagawa Plant"}
      # send an event alarm add request to adapter
      # how do we know the work order id and worker attributes.
      # event_alarm_setting = EventAlarmSetting.where(content: security_control.trigger_event_content)[0] or raise "Event alarm not found for #{security_control.trigger_event_content}"
      #adapter = adapter_key(event_alarm_setting.subsystem_setting.subsystem_description.adapter_id)
      adapter = security_control.trigger_subsystem
      
      h = session.find(:security_control)
      if h.nil?
      # create and add the session id
        h = Hash.new
      end
      request_id = SecureRandom.hex(32)
      h[security_control.id] = request_id
      session.add(:security_control, h)

      future_send(session.find(adapter), PDController::Protocol.to_wire('EventAlarmAddRequest', id: security_control.id, work_order_id: 0, request_id: request_id, event_alarm: security_control.trigger_event_content)) 
      obligations = []
      obligation = JSON.parse(PDController::Protocol.to_wire('EventAlarmAddResponse', id: security_control.id, result: 0))
      obligations << Obligation.new(expect_from: adapter, to_receive: obligation, response_timeout: RESPONSE_TIMEOUT)

      # TODO individual message timeout or entire sequence timeout
      # make a promise that all obligations would be received within time_to_complete
      promise = on_promise(obligations: obligations, time_to_complete: 0)

      security_control_success_add_response = PDController::Protocol.to_wire(response_message_class, id: security_control_id, request_id: pa_request_id, result: 0, description: '')
      security_control_failure_add_response = PDController::Protocol.to_wire(response_message_class, id: security_control_id, request_id: pa_request_id, result: -1, description: "Failed to add a security control id #{message['id']}")
        # an interaction is an exchange of promises which hold obligations to be fullfilled in the future
        # the operation attribute specifies the name of the operation associated with this interaction
        # the name of the interaction useful when debugging
      interaction = interaction_without_transition(name: "#{self.class.name}", 
        exchange: promise, 
        success_action: send_reply(dest_pa, security_control_success_add_response), 
        failure_action: send_reply(dest_pa, security_control_failure_add_response))
        session.add_entry(interaction)
    rescue => e
      error = PDRequestError.new(-1, "Failed to add a security control #{e.message}")
      reply = PDController::Protocol.to_wire(response_message_class, id: security_control_id, request_id: pa_request_id, result: error.result, description: error.description)
      future_send(session.find(DEST_PA), reply)
    end
    return NoActionInteraction
  end

  def send_reply(dest, reply)
    Proc.new do |t|
      future_send(dest, reply)
    end
  end
end

class SecurityControlUpdateRequest < Message
  def parse_message(message, params)
    session = params[:session]
    dest_pa = session.find(DEST_PA)

    update_sc_id = message['update_id']
    # get the new updated sc id
    temporary_sc_id = message['temporary_id']
    pa_request_id = message['request_id']

    begin 
      before_sc = SecurityControl.find(update_sc_id) or raise"Failed to read a security control #{update_sc_id} from db"
      after_sc = SecurityControl.find(temporary_sc_id) or raise"Failed to read a security control #{temporary_sc_id} from db"
      h = session.find(:security_control)
      unless h.nil?
        before_request_id = h[update_sc_id]
        obligations = []
        # figure out the difference between the two security control records.
        #if before_sc.trigger_subsystem != after_sc.trigger_subsystem
        before_adapter = before_sc.trigger_subsystem
        future_send(session.find(before_adapter), PDController::Protocol.to_wire('EventAlarmDeleteRequest', id: update_sc_id, request_id: before_request_id))

        response_msg = JSON.parse(PDController::Protocol.to_wire('EventAlarmDeleteResponse', id: update_sc_id, result: 0))
        obligations.push(Obligation.new(expect_from: before_adapter, to_receive: response_msg))
        #end
        # send a new security control to adapter after deleting the previous one
        #if before_sc.trigger_event_content != after_sc.trigger_event_content
        after_adapter = after_sc.trigger_subsystem
          # although it has been deleted the updated id remains the same
        request_id = SecureRandom.hex(32)
        future_send(session.find(after_adapter), PDController::Protocol.to_wire('EventAlarmAddRequest', id: update_sc_id, work_order_id: 0, request_id: request_id, event_alarm: after_sc.trigger_event_content))

        response_msg = JSON.parse(PDController::Protocol.to_wire('EventAlarmAddResponse', id: update_sc_id, result: 0))
        obligations.push(Obligation.new(expect_from: after_adapter, to_receive: response_msg))

        sc_success_update_response = PDController::Protocol.to_wire(response_message_class, update_id: update_sc_id, temporary_id: temporary_sc_id, request_id: pa_request_id, result: 0, description: '')
        sc_failure_update_response = PDController::Protocol.to_wire(response_message_class, update_id: update_sc_id, temporary_id: temporary_sc_id, request_id: pa_request_id, result: -1, description: "Failed to update a security control id #{update_sc_id}")
        if obligations.length > 0
          promise = on_promise(obligations:obligations, time_to_complete: 2)


          interaction = interaction_without_transition(name: "#{self.class.name}", 
            exchange: promise, 
            success_action: send_reply(dest_pa, sc_success_update_response, session, update_sc_id, request_id), 
            failure_action: failure_send_reply(dest_pa, sc_failure_update_response))
          session.add_entry(interaction)
        else
          future_send(dest_pa, sc_success_update_response)
        end
      else
        raise "Unable to find request id for security control update id #{update_sc_id}"
      end
    rescue => e
      error = PDRequestError.new(-1, "Failed to update a security control #{e.message}")
      reply = PDController::Protocol.to_wire(response_message_class, update_id: update_sc_id, temporary_id: temporary_sc_id, request_id: pa_request_id, result: error.result, description: error.description)
      future_send(dest_pa, reply)
    end
    return NoActionInteraction
  end

  def send_reply(dest, reply, session, update_sc_id, request_id)
    Proc.new do |t|
      h = session.find(:security_control)
      h[update_sc_id] = request_id
      future_send(dest, reply)
    end
  end

  def failure_send_reply(dest, reply)
    Proc.new do |t|
      future_send(dest, reply)
    end
  end
end

# This class is responsible for processing the SecurityControlDeleteRequest message received from PA.
#
class SecurityControlDeleteRequest < Message
  def parse_message(message, params)
    session = params[:session]
    security_control_id = message["id"]
    dest_pa = session.find(DEST_PA)
    pa_request_id = message['request_id']

    begin
      # read the record to be deleted from db.
      security_control = SecurityControl.find(security_control_id) or raise "Failed to read a security control #{security_control_id} from db"
      adapter = security_control.trigger_subsystem
      
      # read the request_id from the in-memory hash matched by the given seccurity control id. 
      # It should already exists added when SecurityControlAddRequest is received.
      h = session.find(:security_control)
      unless h.nil?
        request_id = h[security_control_id]
        # send the event alarm delete request to adapter
        future_send(session.find(adapter), PDController::Protocol.to_wire('EventAlarmDeleteRequest', id: security_control_id, request_id: request_id))
        
        # create an event alarm delete response expected to be received from the adapter
        response_msg = JSON.parse(PDController::Protocol.to_wire('EventAlarmDeleteResponse', id: security_control_id, result: 0)) 
        obligations = []

        obligations.push(Obligation.new(expect_from: adapter, to_receive: response_msg))
        promise = on_promise(obligations: obligations, time_to_complete: 2)

        # create a succesfull security control delete response to forward to PA if the evant alarm delete response received from adapter
        sc_success_delete_response = PDController::Protocol.to_wire(response_message_class, id: security_control_id, request_id: pa_request_id, result: 0, description: '')

        # create a failure security control delete response to forward to PA if the event alarm delete response not received from adapter
        sc_failure_delete_response = PDController::Protocol.to_wire(response_message_class, 
          id: security_control_id, request_id: pa_request_id, result: -1, 
          description: "Failed to delete the security control id #{security_control_id}, request_id #{pa_request_id}")

        # create an interaction to manage all the  above.
        interaction = interaction_without_transition(name: "#{self.class.name}", 
          exchange: promise, 
          success_action: send_reply(dest_pa, sc_success_delete_response),
          failure_action: send_reply(dest_pa, sc_failure_delete_response)
        )
        session.add_entry(interaction)
      end
    rescue => e
      error = PDRequestError.new(-1, "Failed to delete a security control #{e.message}")
      reply = PDController::Protocol.to_wire(response_message_class, id: security_control_id, request_id: pa_request_id, result: error.result, description: error.description)
      future_send(dest_pa, reply)
    end
    NoActionInteraction
  end

  def send_reply(dest, reply)
    Proc.new do |t|
      future_send(dest, reply)
    end
  end
end

class SecurityControlAddResponse < Message
  def parse_message(message, params)
  end
end

class SecurityControlUpdateResponse < Message
  def parse_message(message, params)
  end
end

class SecurityControlDeleteResponse < Message
  def parse_message(message, params)
  end
end

class SecurityControlActionRequest < Message
  def parse_message(message, params)
  end
end

class SecurityControlActionResponse < Message
  def parse_message(message, params)
    session = params[:session]
    source = message['adapter_id']
    interaction = interaction_on_message(session, source, message)
    interaction
  end
end

