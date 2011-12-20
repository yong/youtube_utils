require 'net/http'
require 'uri'

#http://unlockforus.blogspot.com/2010/04/downloading-youtube-videos-not-working.html
#http://board.jdownloader.org/showthread.php?t=18520
#http://userscripts.org/topics/83095?page=1#posts-372119
class YoutubeUtils

  def initialize(debug = false)
    @debug = debug
  end

  def get_videos youtube_watch_url
    res = get_webpage(youtube_watch_url);
    unless res.code == '200'
      raise res.code 
    end
    
    result = []
    
    fmt_stream_map = get_url_encoded_fmt_stream_map(res.body)
		fmt_list = get_fmt_list(res.body)
    puts fmt_stream_map, fmt_list if @debug

		result.concat(parse_fmt_stream_map(fmt_stream_map, fmt_list)) if fmt_list&&fmt_stream_map
    
    return result
  end
  
  #input: http://www.youtube.com/watch?v=cRdxXPV9GNQ
  #output: cRdxXPV9GNQ
  def self.get_vid url
    querys = URI.parse(url).query.split('&')
		querys.each {|x|
		  a = x.split('=')
		  if a[0] == 'v'
		    return a[1]
		  end
		}
		return nil
  end
  
  #input: video/webm; codecs="vp8.0, v
  #outut: webm
  def self.type2suffix type
    return type.split(';')[0].split('/')[1]
  end
  
  private
  
  def convert_itag_to_type itag
    case itag.to_i
    when 0, 6
      return "video/flv; codecs=\"h263, mp3 mono\""
    when 5
      return "video/flv; codecs=\"h263, mp3 stereo\""
    when 34, 35
      return "video/flv; codecs=\"h264, aac stereo\""
    when 13
      return "video/3gp; codecs=\"h263, amr mono\""
    when 17
      return "video/3gp; codecs=\"h264 aac stereo\""
    when 18, 22, 37, 38, 78
      return "video/mp4; codecs=\"h264, aac stereo\""
    when 43, 45
      return "video/webm; codecs=\"vp8, vorbis stereo\""
    else
      return "unknown #{itag}"
    end
  end

  def querystring_2_hash s
    h = {}
    s.split("\\u0026").each { |x|
      a = x.split("=")
      h[a[0]] = a[1] 
    }
    h
  end
  
  #url=http://o-o.preferred.comcast-iad1.v2.lscache7.c.youtube.com/videoplayback?sparams=id%2Cexpire%2Cip%2Cipbits%2Citag%2Csource%2Calgorithm%2Cburst%2Cfactor%2Ccp&fexp=907508%2C903945%2C912602&algorithm=throttle-factor&itag=5&ip=69.0.0.0&burst=40&sver=3&signature=188F0E975207AB14B86050D0D21CFFFEFBCE4B00.D4BF3A75D2670F58B4FF4FF3AFADD1174A9EE574&source=youtube&expire=1324417594&key=yt1&ipbits=8&factor=1.25&cp=U0hRSVRMVV9OTkNOMV9MRllGOjdZSVc4aUgtZUFB&id=ef388a3d0169fd70\u0026quality=small\u0026fallback_host=tc.v2.cache7.c.youtube.com\u0026type=video/x-flv\u0026itag=5
  #22/1280x720/9/0/115
  def parse_fmt_stream_map fmt_stream_map, fmt_list
    result = []
    a1 = fmt_stream_map.split(',')
    a2 = fmt_list.split(',')
    i = 0
    a1.each {|x|
      h = querystring_2_hash(x)
      itag = h['itag']
      url = h['url']
      
      a21 = a2[i].split('/')
      resolution = a21[1]
      result << {'url' => URI.unescape(url), 'type' => convert_itag_to_type(itag), 'quality' => resolution2quality(resolution)}
      i += 1;
    }
    return result
  end
  
  def resolution2quality resolution
    height = resolution.split('x')[1].to_i
    if height > 1080
      return "Original"
    elsif height > 720
      return "1080p"
    elsif height > 576
      return "720p"
    elsif height > 360
      return "480p"
    elsif height > 240
      return "360p"
    else
      return "240p"
    end
  end
  
  def get_webpage youtube_watch_url
    uri = URI.parse(youtube_watch_url)
    res = Net::HTTP.start(uri.host, uri.port) { |http|
      http.get(uri.path + "?" + uri.query, {'Cookie' => 'PREF=f2=40000000'})
    }
    
    return res
  end
  
  def json_to_hash js
    json = StringIO.new(js)
    parser = Yajl::Parser.new
    begin
      return parser.parse(json)
    rescue
      puts "Unable to parse as json"
      return nil
    end
  end
  
  def get_fmt_list body
    body[/\"fmt_list\":\s?\"(.+?)\"/]
    return $1
  end

  def get_url_encoded_fmt_stream_map body
    body[/\"url_encoded_fmt_stream_map\":\s?\"(.+?)\"/]
    return $1
  end
end

if __FILE__ == $0
  p YoutubeUtils.new(true).get_videos "http://www.youtube.com/watch?v=7ziKPQFp_XA"
end

