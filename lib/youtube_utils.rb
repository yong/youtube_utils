require 'rubygems'
require 'net/http'
require 'yajl'

#http://unlockforus.blogspot.com/2010/04/downloading-youtube-videos-not-working.html
#http://board.jdownloader.org/showthread.php?t=18520
class YoutubeUtils
  def get_video youtube_watch_url
    res = get_webpage(youtube_watch_url);
    unless res.code == '200'
      puts res.code
      return []
    end
    
    hash = json_to_hash(get_PLAYER_CONFIG(res.body))
    unless hash
      puts "no PLAYER_CONFIG"
      return []
    end
    
    args = hash['args']
    unless args
      puts "no args"
      return []
    end
    
    result = []
    
		html5_fmt_map = args['html5_fmt_map']
		result.concat(convert_html5_fmt_map(html5_fmt_map)) if html5_fmt_map
		
		fmt_stream_map = args['fmt_stream_map']
		fmt_list = args['fmt_list']
		result.concat(convert_fmt_stream_map(fmt_stream_map, fmt_list)) if fmt_list&&fmt_stream_map
    
    return result
  end
  
  private
  
  def convert_itag_to_type itag
    case itag.to_i
    when 0, 6
      return "audio/mp3; codecs=\" H.263, mp3 mono\""
    when 5
      return "audio/mp3; codecs=\"h263, mp3 stereo\""
    when 34, 35
      return "video/flv; codecs=\"h264, aac stereo\""
    when 13
      return "video/3gp; codecs=\"h263, amr mono\""
    when 17
      return "video/3gp; codecs=\"h264 aac stereo\""
    when 18, 22, 37, 38, 78
      return "video/mp4; codecs=\"h264, aac stereo\""
    when 43, 45
      return "video/webm; codecs=\"vp8.0, vorbis stereo\""
    else
      return "unknown #{itag}"
    end
  end
  
  #{"url"=>"http://v5.lscache8.c.youtube.com/videoplayback?...", "type"=>"video/webm; codecs=\"vp8.0, vorbis\"", "itag"=>43, "quality"=>"medium"}
  def convert_html5_fmt_map a
    result = []
    a.each {|x|
      result << {'url' => x['url'], 'type' => x['type'], 'quality' => x['quality']}
    }
    return result
  end
  
  #22/1280x720/9/0/115
  def convert_fmt_stream_map fmt_stream_map, fmt_list
    result = []
    a1 = fmt_stream_map.split(',')
    a2 = fmt_list.split(',')
    i = 0
    a1.each {|x|
      a11 = x.split('|')
      itag = a11[0]
      url = a11[1]
      
      a21 = a2[i].split('/')
      resolution = a21[1]
      result << {'url' => url, 'type' => convert_itag_to_type(itag), 'quality' => resolution2quality(resolution)}
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
  
  def get_PLAYER_CONFIG body
    body[/\'PLAYER_CONFIG\':(.*)\}\)\;\n/]
    return $1
  end
end

if $0 == __FILE__
  require 'pp'
  pp YoutubeUtils.new.get_video 'http://www.youtube.com/watch?v=cRdxXPV9GNQ'
  #pp YoutubeUtils.new.get_video 'http://www.youtube.com/watch?v=gEtuXrV_KnM'
end
