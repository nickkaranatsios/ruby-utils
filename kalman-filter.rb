require 'pp'

class KalmanFilter
  MIN_LIST_LENGTH = 7
  MAX_LIST_LENGTH = 1000
  ALPHA = 0.3
  COVARIANCE_MAX = 3.0
  attr_accessor :observed_value_list
  
  def initialize
    @covarianceQ = 0.001
    @covarianceR = 1.0
    @variableP = 1.0
    @variableK = 1.0
    @variableX = 0.0
    @first_time = true
    @observed_value_list = []
  end
  
  def adaptive_filter(observed_value)
   predicted_value = 0.0;
   @observed_value_list << observed_value
   if observed_value_list.size >= MIN_LIST_LENGTH
      covarianceQ = @covarianceQ;
     
      covarianceR = calculate_variance(@observed_value_list)
      covarianceR *= ALPHA

      covarianceR = COVARIANCE_MAX if covarianceR > COVARIANCE_MAX
      @covarianceQ, @covarianceR = covarianceQ, covarianceR
      predicted_value = filter(observed_value)
   else
     predicted_value = filter(observed_value)
   end
   if @observed_value_list.size > MAX_LIST_LENGTH
     @observed_value_list.delete(@observed_value_list[0])
   end
   return predicted_value
  end

  def filter(value)
    if @first_time
      @variableX = value;
      @variableP = 1.0;
      @first_time = false;
      return @variableX;
    end
    xHatMinus = @variableX;
    pMinus = @variableP + @covarianceQ;
    @variableK = pMinus / (pMinus + @covarianceR);
    @variableX = xHatMinus + @variableK * (value - xHatMinus);
    @variableP = (1.0 - @variableK) * pMinus;
    return @variableX;
  end

  def calculate_variance(list)
    return 0 if list.size == 1
    sum = list.inject(:+)
    avg = sum / list.size.to_f
    variance = 0.0
    list.each do |e|
      tmp = avg - e
      variance += tmp * tmp
    end
    variance /= list.size - 1.0
    return variance
  end
end

kalman = KalmanFilter.new
(1..20).each do  |i|
  num = rand(100..5000) * 10**6
  predicted_value =  kalman.adaptive_filter(num)
  puts predicted_value
end
pp kalman.observed_value_list

