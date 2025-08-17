require 'httparty'
require 'json'

require 'json'

class GeminiClient
  def initialize
    @api_key = ENV['GEMINI_API_KEY']
  end

  def extract_market_size(content)
    prompt = <<~PROMPT
      次のホームページから米ドルの市場規模を抽出してください:\n#{content}\n
      もし市場規模が見つからない場合は「見つかりません」と返してください。
      出力形式は必ず以下のようなJSON形式で返してください:
      {
        "2024年": "〇〇ドル",
        "〇〇年": "〇〇ドル"
      }
    PROMPT

    uri = URI.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=#{@api_key}")
    headers = { 'Content-Type' => 'application/json' }
    body = {
      contents: [
        {
          parts: [
            { text: prompt }
          ]
        }
      ]
    }

    begin
      response = Net::HTTP.post(uri, body.to_json, headers)
      puts "[DEBUG] raw HTTP response: #{response.inspect}"
      result = JSON.parse(response.body)
      puts "[DEBUG] Gemini response raw: #{result.inspect}"

      text = result.dig('candidates', 0, 'content', 'parts', 0, 'text')

      unless text
        puts '[WARN] Gemini response did not contain expected structure'
        return {}
      end

      parse_json(text)
    rescue StandardError => e
      puts "[ERROR] Gemini response parsing failed: #{e.class} #{e.message}"
      puts e.backtrace.join("\n")
      {}
    end
  end

  def parse_json(text)
    # JSONらしき部分を抽出
    json_str = text[/\{.*?\}/m]

    unless json_str
      puts "[WARN] Gemini did not return JSON format: #{text}"
      return {}
    end

    JSON.parse(json_str)
  rescue StandardError => e
    puts "[ERROR] JSON parsing failed: #{e.message}"
    {}
  end
end
