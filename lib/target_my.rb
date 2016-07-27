require 'curb'
require 'json'

class TargetMy

  attr_accessor :login, :password, :app_link, :app_name, :app_id

  def initialize(login, password, app_link, app_name)
    @login = login
    @password = password
    @app_link = app_link
    @app_name = app_name
    @app_id = nil
  end

  def create_and_bind_app
    raise 'Application already exists and attached' unless @app_id.nil?
    request = auth
    request.follow_location = true
    request.url = 'https://target.my.com/create_pad_groups/'
    request.http_get
    request.follow_location = false
    request.url = 'https://target.my.com/api/v2/pad_groups.json'
    request.headers['X-CSRFToken'] = request.header_str.match(/(?<=csrftoken=)(.*?)(?=;)/)
    request.headers['Origin'] = 'https://target.my.com'
    request.headers['Referer'] = 'https://target.my.com/create_pad_groups/'
    request.http_post("{\"url\":\"#{@app_link}\",\"platform_id\":6122,\"description\":\"#{@app_name}\",\"pads\":[{\"description\":\"standart\",\"format_id\":6124,\"filters\":{\"deny_mobile_android_category\":[],\"deny_mobile_category\":[],\"deny_topics\":[],\"deny_pad_url\":[]},\"js_tag\":false,\"shows_period\":\"day\",\"shows_limit\":null,\"shows_interval\":null}]}")
    raise "Creating app failed with status #{request.status}" if request.status != '200 OK'
    @app_id = JSON.parse(request.body_str)['id']
  end

  def add_fullscreen_block
    raise 'Application does not created' if @app_id.nil?
    request = auth
    request.follow_location = true
    request.url = "https://target.my.com/pad_groups/#{@app_id}/create/"
    request.http_get
    request.follow_location = false
    request.url = "https://target.my.com/api/v2/pad_groups/#{@app_id}/pads.json"
    request.headers['X-CSRFToken'] = request.header_str.match(/(?<=csrftoken=)(.*?)(?=;)/)
    request.headers['Origin'] = 'https://target.my.com'
    request.headers['Referer'] = "https://target.my.com/pad_groups/#{@app_id}/create/"
    request.http_post("{\"description\":\"fullscreen\",\"format_id\":6440,\"filters\":{\"deny_mobile_android_category\":[],\"deny_mobile_category\":[],\"deny_topics\":[],\"deny_pad_url\":[]},\"js_tag\":false,\"shows_limit\":null,\"shows_interval\":null}")
    raise "Creating ad unit failed with status #{request.status}" if request.status != '200 OK'
  end

  def slot_ids
    raise 'Application does not created' if @app_id.nil?
    request = auth
    request.follow_location = true
    request.url = "https://target.my.com/api/v2/pad_groups/#{@app_id}.json"
    request.http_get
    links = JSON.parse(request.body_str)['pads'].collect { |pad| "https://target.my.com/api/v1/pads/#{pad['id']}.json" }

    result = {}
    links.each do |link|
      request.url = link
      request.http_get
      response = JSON.parse(request.body_str)
      format = case response['format_id']
               when 6124
                 'standard'
               when 6440
                 'fullscreen'
               else
                 "#{response['format_id']} is undefined"
               end
      result[response['slot_id']] = format
    end
    result
  end

  private

  def auth
    @request ||= begin
      request = Curl::Easy.new('https://auth-ac.my.com/auth')
      request.enable_cookies = true
      request.headers['User-Agent'] = 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:42.0) Gecko/20100101 Firefox/42.0'
      request.headers['Origin'] = 'https://account.my.com'
      request.headers['Referer'] = 'https://account.my.com/profile/userinfo/'
      request.http_post("email=#{@login}&password=#{@password}")
      raise 'Auth failed' if request.redirect_url != 'http://mail.my.com/'
      request
    end
  end
end
