require 'httparty'
require 'nokogiri'
require 'pdf-reader'
require 'open-uri'
require 'cgi'
require_relative './gemini_client'

class MarketSizeScraper
  attr_reader :gemini

  HEADERS = {
    'User-Agent' => 'Mozilla/5.0'
  }

  def initialize
    @gemini = GeminiClient.new
  end

  def duckduckgo_search(keyword)
    search_url = "https://duckduckgo.com/html/?q=#{CGI.escape(keyword)}"
    res = HTTParty.get(search_url, headers: HEADERS)
    doc = Nokogiri::HTML(res.body)

    doc.css('.result__title a').first(3).map do |a|
      href = a['href']
      uri = URI.parse("https:#{href}")
      query = CGI.parse(uri.query)
      query['uddg']&.first
    end.compact
  end

  def fetch_content(url)
    if url.end_with?('.pdf')
      fetch_pdf_content(url)
    else
      fetch_html_content(url)
    end
  end

  def fetch_html_content(url)
    res = HTTParty.get(url, headers: HEADERS)
    doc = Nokogiri::HTML(res.body)
    body = doc.at('body')
    body.css('header, footer, table').remove
    body.text.strip.gsub(/\s+/, "\n")
  rescue StandardError => e
    puts "[ERROR] HTML fetch failed: #{e}"
    ''
  end

  def fetch_pdf_content(url)
    io = URI.open(url)
    reader = PDF::Reader.new(io)
    reader.pages.map(&:text).join("\n")
  rescue StandardError => e
    puts "[ERROR] PDF fetch failed: #{e}"
    ''
  end

  def run(keyword)
    links = duckduckgo_search(keyword)
    links.each do |link|
      puts "[INFO] Fetching: #{link}"
      content = fetch_content(link)
      result = @gemini.extract_market_size(content)
      puts "Market size: #{result}"
    end
  end
end
