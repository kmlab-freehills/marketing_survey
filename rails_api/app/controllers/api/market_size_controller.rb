class Api::MarketSizeController < ApplicationController
  skip_before_action :verify_authenticity_token

  def search
    industry = params[:industry]
    currency = params[:currency]

    unless industry.present? && currency.present?
      return render json: { error: "industry and currency are required" }, status: :bad_request
    end

    query = "市場規模 #{industry} #{currency}"

    scraper = MarketSizeScraper.new
    links = scraper.duckduckgo_search(query)
    results = []

    links.each do |link|
      content = scraper.fetch_content(link)
      market_data = scraper.gemini.extract_market_size(content)
      results << { link: link, market_size: market_data }
    end

    render json: { industry:, currency:, results: }
  end
end
