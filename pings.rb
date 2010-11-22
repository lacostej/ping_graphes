# generates a SVG graph of the ping times collected from the output of a ping -D hostname
#
# initial idea for the SVG graph: the first script used in Refactoring in Ruby (ISBN-13: 978-0321545046)
#
# Author: jerome.lacoste@gmail.com
#
width = 1120
height = 630

def rect(centre_x, centre_y)
  %Q{<rect x="#{centre_x-2}" y="#{centre_y-2}"
    width="4" height="4"
    fill="red" stroke="none" stroke-width="0" />"}
end

def text(centre_x, centre_y, value, font_size)
  %Q{<text x="#{centre_x+6}" y="#{centre_y+4}"
    font-family="Verdana" font-size="#{font_size}"
    fill="red" >#{value} </text>"}
end

def line(x1, y1, x2, y2)
  %Q{<line x1="#{x1}" y1="#{y1}" x2="#{x2}" y2="#{y2}" 
           stroke="#999" stroke-width="1" />}
end

def polyline(points)
  %Q{<polyline fill="none" stroke="#333" stroke-width="1" 
        points = "#{points.join(' ')}" />}
end

def spark(centre_x, centre_y, value)
  "#{rect(centre_x, centre_y)}
  #{text(centre_x, centre_y, value, 12)}"
end

def svg_coord(point)
  "#{point[0]},#{point[1]}"
end

class ScaledGraph
  attr_accessor :width, :height, :min_x, :min_y, :max_x, :max_y

  def initialize(width, height, points)
    xs = points.collect { |x| x[0] }
    ys = points.collect { |x| x[1] }
    @width = width
    @height = height
    @min_y = ys.min
    @max_y = ys.max
    @min_x = xs.min
    @max_x = xs.max
  end
  
  def scaled_point(point)
    [ ((point[0]-@min_x)*@width)/(@max_x-@min_x), ((@max_y-point[1])*@height)/(@max_y-@min_y) ]
  end
  
  def title_start_point()
    # 20% from the left, 5% below the 0 line
    [@width * 0.2, scaled_point([0, -0.05*@max_y])[1]]
  end
end

def svg(width, height, points, title)
  graph = ScaledGraph.new(width, height, points)
  
  scaled_points = points.collect { |p| svg_coord(graph.scaled_point(p))}

  start_line = graph.scaled_point([0, 0])
  stop_line = graph.scaled_point([points[-1][0], 0])
  
  spark = graph.scaled_point(points[-1])
  title_start = graph.title_start_point()

  %Q{<svg xmlns="http://www.w3.org/2000/svg" 
        xmlns:xlink="http://www.w3.org/1999/xlink" >
 #{line(start_line[0], start_line[1], stop_line[0], stop_line[1])}
 #{polyline(scaled_points)}
 #{spark(spark[0], spark[1], points[-1][1])}
 #{text(title_start[0], title_start[1], title, 20)}
</svg>}
end

#########################################################
class PingOutputFile
  attr_accessor :pings, :title

  def initialize(ping_output_file)
    dest = ''
    values = []
    File.open(ping_output_file).each do |line|
      # PING google.com (74.125.77.147) 56(84) bytes of data.
      if line =~ /PING (.*) \(.*/
        dest = $1
      end
      # [1290183567.704183] 64 bytes from ew-in-f147.1e100.net (74.125.77.147): icmp_req=2 ttl=46 time=7647 ms
      # [ 1290183567.704183 , 7646 ]
      if line =~ /\[(.*)\].*time=(.*) ms/
        l = [$1, $2]
        ping_time = Integer(l[1])
        sent = (Float(l[0]) - Float(ping_time) / 1000)
        #print "#{sent} <> #{ping_time}"
        val = [sent, ping_time]
        values << val
      end
    end
    @pings = values
    time_s = Time.at(Float(values[0][0]))
    @title = "PING #{dest} #{time_s} (#{ping_output_file})"
  end
end

if (ARGV.length != 1)
  if ARGV.length > 1
    $stderr.puts "extra arguments not needed: #{ARGV[1, ARGV.length-1].join(', ')}"
  else
    $stderr.puts "missing required file argument"
  end
  puts "Usage: pings.rb <ping_output_file>"
  exit(-1)
end
    
ping_file = PingOutputFile.new(ARGV[0])

svgContent = svg(width, height, ping_file.pings, ping_file.title)

puts svgContent
