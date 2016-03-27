// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <fstream>
#include "net/tools/quic/quic_server_session_base.h"
#include "net/tools/quic/quic_simple_server_stream.h"

#include "base/logging.h"
#include "base/bind.h"
#include "base/strings/string_number_conversions.h"
#include "net/quic/proto/cached_network_parameters.pb.h"
#include "net/quic/quic_bug_tracker.h"
#include "net/quic/quic_connection.h"
#include "net/quic/quic_flags.h"
#include "net/quic/quic_spdy_session.h"
#include "net/quic/reliable_quic_stream.h"

using base::StringToInt;
using namespace std;

namespace net {

class QuicWriteCompleteAck : public QuicAckListenerInterface {
  public:
    QuicWriteCompleteAck(QuicServerSessionBase* session)
      :session_(session) {}
    
    void OnPacketAcked(int /*acked_bytes*/,
                     QuicTime::Delta /*ack delay time*/) override {
      PacketAcked();
    }
    void OnPacketRetransmitted(int /* retransmitted_bytes */) override {}
  protected:
    ~QuicWriteCompleteAck() override {}
  private:
    void PacketAcked() {
      session_->PacketAcked();
    }
    QuicServerSessionBase* session_;
    DISALLOW_COPY_AND_ASSIGN(QuicWriteCompleteAck);
};

QuicServerSessionBase::QuicServerSessionBase(
    const QuicConfig& config,
    QuicConnection* connection,
    QuicServerSessionVisitor* visitor,
    const QuicCryptoServerConfig* crypto_config,
    QuicCompressedCertsCache* compressed_certs_cache)
    : QuicSpdySession(connection, config),
      crypto_config_(crypto_config),
      compressed_certs_cache_(compressed_certs_cache),
      visitor_(visitor),
      bandwidth_resumption_enabled_(false),
      bandwidth_estimate_sent_to_client_(QuicBandwidth::Zero()),
      last_scup_time_(QuicTime::Zero()),
      last_scup_packet_number_(0) {}

QuicServerSessionBase::~QuicServerSessionBase() {}

void QuicServerSessionBase::Initialize() {
  crypto_stream_.reset(
      CreateQuicCryptoServerStream(crypto_config_, compressed_certs_cache_));
  QuicSpdySession::Initialize();
  ack_listener_ = new QuicWriteCompleteAck(this);
  const char *fn = "./out/Debug/SampleVideo_720x480_20mb.mp4";
  file_.open(fn, ios::in | ios::binary);
  if (file_.is_open()) {
		file_.seekg(0, file_.end);
    file_length_ = file_.tellg();
    file_.seekg(0, file_.beg);
    send_header_ = false;
    send_length_ = 0;
    DVLOG(1) << "file opened successfully on length " << file_length_;
  } else {
    DVLOG(1) << "Failed to open file " << fn;
  }
}

void QuicServerSessionBase::OnConfigNegotiated() {
  QuicSession::OnConfigNegotiated();

  if (!config()->HasReceivedConnectionOptions()) {
    return;
  }

  // Enable bandwidth resumption if peer sent correct connection options.
  const bool last_bandwidth_resumption =
      ContainsQuicTag(config()->ReceivedConnectionOptions(), kBWRE);
  const bool max_bandwidth_resumption =
      ContainsQuicTag(config()->ReceivedConnectionOptions(), kBWMX);
  bandwidth_resumption_enabled_ =
      last_bandwidth_resumption || max_bandwidth_resumption;

  // If the client has provided a bandwidth estimate from the same serving
  // region as this server, then decide whether to use the data for bandwidth
  // resumption.
  const CachedNetworkParameters* cached_network_params =
      crypto_stream_->PreviousCachedNetworkParams();
  if (cached_network_params != nullptr &&
      cached_network_params->serving_region() == serving_region_) {
    if (FLAGS_quic_log_received_parameters) {
      connection()->OnReceiveConnectionState(*cached_network_params);
    }

    if (bandwidth_resumption_enabled_) {
      // Only do bandwidth resumption if estimate is recent enough.
      const int64_t seconds_since_estimate =
          connection()->clock()->WallNow().ToUNIXSeconds() -
          cached_network_params->timestamp();
      if (seconds_since_estimate <= kNumSecondsPerHour) {
        connection()->ResumeConnectionState(*cached_network_params,
                                            max_bandwidth_resumption);
      }
    }
  }
}

void QuicServerSessionBase::OnConnectionClosed(QuicErrorCode error,
                                               ConnectionCloseSource source) {
  QuicSession::OnConnectionClosed(error, source);
  // In the unlikely event we get a connection close while doing an asynchronous
  // crypto event, make sure we cancel the callback.
  if (crypto_stream_.get() != nullptr) {
    crypto_stream_->CancelOutstandingCallbacks();
  }
  visitor_->OnConnectionClosed(connection()->connection_id(), error);
}

void QuicServerSessionBase::OnWriteBlocked() {
  DVLOG(1) << "Connection blocked ";
  QuicSession::OnWriteBlocked();
  visitor_->OnWriteBlocked(connection());
}

void QuicServerSessionBase::OnCanWrite() {
  DVLOG(1) << "On can write called";
  std::unordered_map<unsigned int, net::ReliableQuicStream *> streams = dynamic_streams();
  for (std::unordered_map<unsigned int, net::ReliableQuicStream *>::const_iterator it = streams.begin(); it != streams.end(); ++it) {
    QuicSimpleServerStream* stream = static_cast<QuicSimpleServerStream*>(it->second);
    DVLOG(1) << "reliable stream " << stream->id();
    DVLOG(1) << "HasDataToWrite() " << HasDataToWrite();
    DVLOG(1) << "flow controller is blocked " << stream->flow_controller()->IsBlocked();
    DVLOG(1) << "send window size " << stream->flow_controller()->SendWindowSize() << " send length " << send_length_;
    bool can_tx = true;
    while (stream->flow_controller()->IsBlocked() == false && can_tx && send_length_ < stream->flow_controller()->SendWindowSize()) {
      can_tx = SendNextResponse(stream);
      DVLOG(1) << "Send window size " << stream->flow_controller()->SendWindowSize();
      DVLOG(1) << "Has data to write " << HasDataToWrite();
      DVLOG(1) << "connection can write stream data " << connection()->CanWriteStreamData();
    }
  }
}

bool QuicServerSessionBase::SendNextResponse(QuicSimpleServerStream* stream) {
  bool send_fin = false;
  file_length_ -= 1024;
  if (file_length_ <= 0) {
    DVLOG(1) << "complete sending all file ";
    file_.close();
    return false;
  }
  int length = 1024;
  if (file_length_ < 1024) {
    length = file_length_;
  }
  char* buffer = new char[length];

  DVLOG(1) << "length to send " << length << " left length " << file_length_;
  file_.read(buffer, length); 
  if (file_) {
    if (send_header_ == false) {
      SpdyHeaderBlock headers;
      headers[":status"] = "200";
      headers["content-length"] = base::IntToString(file_length_ + 1024);
      stream->WriteHeaders(headers, send_fin, nullptr); 
      send_header_ = true;
    }

    StringPiece message(buffer, length);
    // stream->WriteData(message, send_fin);
    // connection()->writer()->WritePacket(buffer, length, connection()->self_address().address(), connection()->peer_address(),nullptr);
    
    struct iovec iov;
    QuicIOVector data_iov(MakeIOVector(message, &iov));
    connection()->SendStreamData(stream->id(), data_iov, send_length_, false, ack_listener_.get()); 
    send_length_ += length;
    DVLOG(1) << "Writing body (fin = " << send_fin
           << ") with size: " << length << " offset " << send_length_;
    if (length == file_length_) {
      stream->WriteTrailers(SpdyHeaderBlock(), nullptr);
    }
  } else {
    DVLOG(1) << "Failed to read " << length;
    file_.close();
    return false;
  }
  delete[] buffer;
  return true;
}

void QuicServerSessionBase::PacketAcked() {
  DVLOG(1) << "On packet acked called" ;
}

void QuicServerSessionBase::OnCongestionWindowChange(QuicTime now) {
  DVLOG(1) << "OnCongestionWindowChange ";
  if (!bandwidth_resumption_enabled_) {
    return;
  }
  // Only send updates when the application has no data to write.
  if (HasDataToWrite()) {
    return;
  }

  // If not enough time has passed since the last time we sent an update to the
  // client, or not enough packets have been sent, then return early.
  const QuicSentPacketManager& sent_packet_manager =
      connection()->sent_packet_manager();
  int64_t srtt_ms =
      sent_packet_manager.GetRttStats()->smoothed_rtt().ToMilliseconds();
  int64_t now_ms = now.Subtract(last_scup_time_).ToMilliseconds();
  int64_t packets_since_last_scup =
      connection()->packet_number_of_last_sent_packet() -
      last_scup_packet_number_;
  if (now_ms < (kMinIntervalBetweenServerConfigUpdatesRTTs * srtt_ms) ||
      now_ms < kMinIntervalBetweenServerConfigUpdatesMs ||
      packets_since_last_scup < kMinPacketsBetweenServerConfigUpdates) {
    return;
  }

  // If the bandwidth recorder does not have a valid estimate, return early.
  const QuicSustainedBandwidthRecorder& bandwidth_recorder =
      sent_packet_manager.SustainedBandwidthRecorder();
  if (!bandwidth_recorder.HasEstimate()) {
    return;
  }

  // The bandwidth recorder has recorded at least one sustained bandwidth
  // estimate. Check that it's substantially different from the last one that
  // we sent to the client, and if so, send the new one.
  QuicBandwidth new_bandwidth_estimate = bandwidth_recorder.BandwidthEstimate();

  int64_t bandwidth_delta =
      std::abs(new_bandwidth_estimate.ToBitsPerSecond() -
               bandwidth_estimate_sent_to_client_.ToBitsPerSecond());

  // Define "substantial" difference as a 50% increase or decrease from the
  // last estimate.
  bool substantial_difference =
      bandwidth_delta >
      0.5 * bandwidth_estimate_sent_to_client_.ToBitsPerSecond();
  if (!substantial_difference) {
    return;
  }

  bandwidth_estimate_sent_to_client_ = new_bandwidth_estimate;
  DVLOG(1) << "Server: sending new bandwidth estimate (KBytes/s): "
           << bandwidth_estimate_sent_to_client_.ToKBytesPerSecond();

  // Include max bandwidth in the update.
  QuicBandwidth max_bandwidth_estimate =
      bandwidth_recorder.MaxBandwidthEstimate();
  int32_t max_bandwidth_timestamp = bandwidth_recorder.MaxBandwidthTimestamp();

  // Fill the proto before passing it to the crypto stream to send.
  CachedNetworkParameters cached_network_params;
  cached_network_params.set_bandwidth_estimate_bytes_per_second(
      bandwidth_estimate_sent_to_client_.ToBytesPerSecond());
  cached_network_params.set_max_bandwidth_estimate_bytes_per_second(
      max_bandwidth_estimate.ToBytesPerSecond());
  cached_network_params.set_max_bandwidth_timestamp_seconds(
      max_bandwidth_timestamp);
  cached_network_params.set_min_rtt_ms(
      sent_packet_manager.GetRttStats()->min_rtt().ToMilliseconds());
  cached_network_params.set_previous_connection_state(
      bandwidth_recorder.EstimateRecordedDuringSlowStart()
          ? CachedNetworkParameters::SLOW_START
          : CachedNetworkParameters::CONGESTION_AVOIDANCE);
  cached_network_params.set_timestamp(
      connection()->clock()->WallNow().ToUNIXSeconds());
  if (!serving_region_.empty()) {
    cached_network_params.set_serving_region(serving_region_);
  }

  crypto_stream_->SendServerConfigUpdate(&cached_network_params);

  connection()->OnSendConnectionState(cached_network_params);

  last_scup_time_ = now;
  last_scup_packet_number_ = connection()->packet_number_of_last_sent_packet();
}

bool QuicServerSessionBase::ShouldCreateIncomingDynamicStream(QuicStreamId id) {
  if (!connection()->connected()) {
    QUIC_BUG << "ShouldCreateIncomingDynamicStream called when disconnected";
    return false;
  }

  if (id % 2 == 0) {
    DVLOG(1) << "Invalid incoming even stream_id:" << id;
    connection()->SendConnectionCloseWithDetails(
        QUIC_INVALID_STREAM_ID, "Client created even numbered stream");
    return false;
  }
  return true;
}

bool QuicServerSessionBase::ShouldCreateOutgoingDynamicStream() {
  if (!connection()->connected()) {
    QUIC_BUG << "ShouldCreateOutgoingDynamicStream called when disconnected";
    return false;
  }
  if (!crypto_stream_->encryption_established()) {
    QUIC_BUG << "Encryption not established so no outgoing stream created.";
    return false;
  }
  if (GetNumOpenOutgoingStreams() >= max_open_outgoing_streams()) {
    VLOG(1) << "No more streams should be created. "
            << "Already " << GetNumOpenOutgoingStreams() << " open.";
    return false;
  }
  return true;
}

QuicCryptoServerStreamBase* QuicServerSessionBase::GetCryptoStream() {
  return crypto_stream_.get();
}

}  // namespace net
