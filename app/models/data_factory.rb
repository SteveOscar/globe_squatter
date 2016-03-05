class DataFactory
  attr_reader :countries, :rates, :base_country

  def initialize(params)
    @countries = Country.includes(:currency).all
    @rates = ExchangeRateService.new(params).get_data["rates"]
    @base_country = Country.includes(:currency).find(params[:country])
  end

  def relative_prices(params)
    prices = {}
    countries.each do |country|
      prices[country.map_code] = calc_relative_expense(country, rates, params) unless rates[country.currency.code].nil? || country.ppp.nil?
    end
    # set_range_for_relative_prices(prices)
    trim_outliers(prices)
  end

  def trim_outliers(prices)
    prices.each {|k, v| prices[k] = v / 10}
    prices
  end

  def calc_relative_expense(country, rates, params)
    exchange_rate = rates[country.currency.code]
    expense_factor = (base_country.ppp.to_f * exchange_rate) / country.ppp.to_f
    expense_factor.round(2)
    # (exchange_rate.to_f / country.ppp.to_f).round(2)
  end

  def exchange_rates(params)
    latest = {}
    countries.each do |country|
      latest[country.map_code] = rates[country.currency.code].to_s unless rates[country.currency.code].nil?
    end
    latest
  end

  def compare_exchange_rates(latest, params, years_back)
    date = format_date(years_back)
    old = historical_data(date, params)
    change = {}
    latest.each do |rate|
      change[rate[0]] = (((rate[1].to_f - old[rate[0]].to_f) / rate[1].to_f) * 100).round(1).to_s
    end
    change
  end

  def format_date(years_back)
    years_back.year.ago.strftime('%Y-%m-%d')
  end

  def historical_data(date, params)
    historical_rates = {}
    rates = ExchangeRateService.new(params).get_historical_data(date)["rates"]
    countries.each do |country|
      historical_rates[country.map_code] = rates[country.currency.code].to_s unless rates[country.currency.code].nil?
    end
    historical_rates
  end

  def generate_title_from_params(params)
    "Perspective: #{base_country.country_name}, base currency: #{base_country.currency.code}"
  end

  def time_frame(params)
    time = "#{params[:time]} year" if params[:time] == "1"
    time = "#{params[:time]} years" if params[:time] != "1"
    time
  end

  def peace_index
    peace_index = {}
    countries.each do |country|
      peace_index[country.map_code] = [country.peace_score.to_s, country.peace_rank.to_s] unless country.peace_score.nil?
    end
    peace_index
  end

end
