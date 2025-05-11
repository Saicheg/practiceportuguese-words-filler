require 'faraday'
require 'faraday/gzip'
require 'json'
require 'nokogiri'
require 'logger'

class PracticePortugueseClient
  BASE_URL = 'https://www.practiceportuguese.com'

  def initialize
    @token = nil
    @security_token = nil
    @logger = SemanticLogger['PracticePortugueseClient']
    @conn = Faraday.new(url: BASE_URL) do |f|
      f.request :url_encoded
      f.request :gzip
      f.adapter Faraday.default_adapter
    end
  end

  def login(username, password)
    response = @conn.post('/wp-json/appp/v1/login') do |req|
      req.headers['Accept'] = '*/*'
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      req.headers['Accept-Language'] = 'en-US;q=1, ru-US;q=0.9, be-US;q=0.8'
      req.headers['Accept-Encoding'] = 'gzip, deflate, br'
      req.headers['User-Agent'] = 'Practice Portuguese/221 (iPhone; iOS 18.4.1; Scale/3.00)'
      req.body = {
        username: username,
        password: password
      }
    end

    unless response.success?
      logger.error("Login failed. Status: #{response.status}")
      logger.error("Response body: #{response.body}")
      raise "Login failed"
    end

    logger.info("Login successful")
    body = JSON.parse(response.body)
    return body["access_token"]
  end

  def get_phrases(token)
    response = @conn.get('/my-phrases/') do |req|
      req.headers['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
      req.headers['User-Agent'] = 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148'
      req.headers['Accept-Language'] = 'en-US,en;q=0.9'
      req.params = {
        'appp' => '3',
        'token' => token
      }
    end

    unless response.success?
      logger.error("Failed to get phrases. Status: #{response.status}")
      logger.error("Response body: #{response.body}")
      return []
    end

    # Extract the initialData JSON from the page
    doc = Nokogiri::HTML(response.body)
    script_content = doc.css('script').find { |script| script.text.include?('initialData') }&.text

    unless script_content
      raise "Failed to find initialData script."
    end

    # Extract the security token from the _wpnonce input field
    @security_token = doc.at_css('input#_wpnonce')&.[]('value')

    unless @security_token
      logger.error("Failed to find security token.")
      raise "Failed to find security token."
    end

    logger.info("Extracted security token successfully.")

    # Extract the JSON part by removing the 'let initialData = ' prefix
    initial_data_json = script_content.gsub(/let initialData = /, '').strip.chomp(';')

    initial_data = JSON.parse(initial_data_json)
    logger.info("Extracted initialData successfully.")

    return initial_data['data'] || []
  end

  def search_phrases(term, token)
    response = @conn.post('/wp-admin/admin-ajax.php') do |req|
      req.headers['Accept'] = 'application/json, text/plain, */*'
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      req.headers['Accept-Language'] = 'en-US,en;q=0.9'
      req.headers['User-Agent'] = 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148'
      req.headers['Origin'] = BASE_URL
      req.headers['Referer'] = "#{BASE_URL}/"
      req.body = {
        'action' => 'pp_search_for_correct_phrases',
        'term' => term,
        'exactMatch' => true,
        'createdByUser' => false,
        'app_token' => token,
        'security' => @security_token
      }
    end

    unless response.success?
      logger.error("Search failed. Status: #{response.status}")
      logger.error("Response body: #{response.body}")
      return []
    end

    body = JSON.parse(response.body)
    return body['data'] || []
  end

  def add_phrase_to_smart_review(phrase_id, token)
    response = @conn.post('/wp-admin/admin-ajax.php') do |req|
      req.headers['Accept'] = 'application/json, text/plain, */*'
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      req.headers['Accept-Language'] = 'en-US,en;q=0.9'
      req.headers['User-Agent'] = 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148'
      req.headers['Origin'] = BASE_URL
      req.headers['Referer'] = "#{BASE_URL}/"
      req.body = {
        'action' => 'pp_new_phrase_to_smart_review',
        'phrase_id' => phrase_id,
        'subAction' => 'add',
        'security' => @security_token,
        'type' => 'smart-review',
        'app_token' => token
      }
    end

    unless response.success?
      logger.error("Failed to add phrase to smart review. Status: #{response.status}")
      logger.error("Response body: #{response.body}")
      return false
    end

    return true
  end

  private

  attr_reader :logger
end 
