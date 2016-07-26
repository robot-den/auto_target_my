require 'curb'
require 'json'

class TargetMy
  def solution(login, password, app_link, app_name)
    request = auth(login, password)
    app_id = create_app(request, app_link, app_name)
    create_fullscreen_ad_unit(request, app_id)
    get_slot_ids(request, app_id)
  end

  private

  def auth(login, password)
    puts 'Логинимся'
    request = Curl::Easy.new('https://auth-ac.my.com/auth')
    request.enable_cookies = true
    request.headers['User-Agent'] = 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:42.0) Gecko/20100101 Firefox/42.0'
    request.headers['Origin'] = 'https://account.my.com'
    request.headers['Referer'] = 'https://account.my.com/profile/userinfo/'
    request.http_post("email=#{login}&password=#{password}")
    raise 'Auth failed' if request.redirect_url != 'http://mail.my.com/'
    request
  end

  def create_app(request, app_link, app_name, first_block_name = 'standard')
    puts 'Добавляем приложение'
    # собираем cookies
    request.follow_location = true
    request.url = 'https://target.my.com/create_pad_groups/'
    request.http_get
    # настраиваем и отправляем запрос
    request.follow_location = false
    request.url = 'https://target.my.com/api/v2/pad_groups.json'
    request.headers['X-CSRFToken'] = request.header_str.match(/(?<=csrftoken=)(.*?)(?=;)/)
    request.headers['Origin'] = 'https://target.my.com'
    request.headers['Referer'] = 'https://target.my.com/create_pad_groups/'
    request.http_post("{\"url\":\"#{app_link}\",\"platform_id\":6122,\"description\":\"#{app_name}\",\"pads\":[{\"description\":\"#{first_block_name}\",\"format_id\":6124,\"filters\":{\"deny_mobile_android_category\":[],\"deny_mobile_category\":[],\"deny_topics\":[],\"deny_pad_url\":[]},\"js_tag\":false,\"shows_period\":\"day\",\"shows_limit\":null,\"shows_interval\":null}]}")
    raise "Creating app failed with status #{request.status}" if request.status != '200 OK'
    JSON.parse(request.body_str)['id']
  end

  def create_fullscreen_ad_unit(request, app_id)
    puts 'Добавляем fullscreen блок'
    # собираем cookies
    request.follow_location = true
    request.url = "https://target.my.com/pad_groups/#{app_id}/create/"
    request.http_get
    # настраиваем и отправляем запрос
    request.follow_location = false
    request.url = "https://target.my.com/api/v2/pad_groups/#{app_id}/pads.json"
    request.headers['X-CSRFToken'] = request.header_str.match(/(?<=csrftoken=)(.*?)(?=;)/)
    request.headers['Origin'] = 'https://target.my.com'
    request.headers['Referer'] = "https://target.my.com/pad_groups/#{app_id}/create/"
    request.http_post("{\"description\":\"fullscreen\",\"format_id\":6440,\"filters\":{\"deny_mobile_android_category\":[],\"deny_mobile_category\":[],\"deny_topics\":[],\"deny_pad_url\":[]},\"js_tag\":false,\"shows_limit\":null,\"shows_interval\":null}")
    raise "Creating ad unit failed with status #{request.status}" if request.status != '200 OK'
  end

  def get_slot_ids(request, app_id)
    puts 'Генерируем список slot_id'
    request.follow_location = true
    links = get_ad_unit_links(request, app_id)
    result = []
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
      result << [format, response['slot_id']]
    end
    result
  end

  def get_ad_unit_links(request, app_id)
    puts 'Получаем ссылки на блоки'
    request.url = "https://target.my.com/api/v2/pad_groups/#{app_id}.json"
    request.http_get
    JSON.parse(request.body_str)['pads'].collect { |pad| "https://target.my.com/api/v1/pads/#{pad['id']}.json" }
  end
end
