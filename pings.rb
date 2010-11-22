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
end

#print svg_coord(scaled_point(width, height, 0, 2500, 0, 40331, [0, 0]))

def svg(width, height, points, title)
  graph = ScaledGraph.new(width, height, points)
  
  scaled_points = []
  points.each { |p| scaled_points << svg_coord(graph.scaled_point(p))}

  start_line = graph.scaled_point([0, 0])
  stop_line = graph.scaled_point([points[-1][0], 0])
  
  spark = graph.scaled_point(points[-1])
  title_start = graph.scaled_point([0, -0.05*(graph.max_y)])

  %Q{<svg xmlns="http://www.w3.org/2000/svg" 
        xmlns:xlink="http://www.w3.org/1999/xlink" >
 #{line(start_line[0], start_line[1], stop_line[0], stop_line[1])}
 #{polyline(scaled_points)}
 #{spark(spark[0], spark[1], points[-1][1])}
 #{text(width *0.2, title_start[1], title, 20)}
</svg>}
end

#########################################################

def load_values(ping_output_file)
  values = []
  first = nil
  File.open(ping_output_file).each do |line|
    # [1290183567.704183] 64 bytes from ew-in-f147.1e100.net (74.125.77.147): icmp_req=2 ttl=46 time=7647 ms
    # [ '1290183567.704183' , '7646' ]
    if line =~ /\[(.*)\].*time=(.*) ms/
      l = [$1, $2]
      time_travel = Integer(l[1])
      sent = Integer((Float(l[0]) - Float(time_travel) / 1000))
      if first == nil
        first = sent
        sent = 0
      else
        sent = sent - first
      end
      #print "#{sent} <> #{time_travel}"
      val = [sent, time_travel]
      values << val
    end
  end
  values
end

def get_title(ping_output_file)
  dest = ''
  time = ''
  File.open(ping_output_file).each do |line|
    if line =~ /PING (.*) \(.*/
      dest = $1
    end
    if line =~ /\[(.*)\].*time=(.*) ms/
      time = $1
      break
    end
  end
  time_s = Time.at(Float(time))
  title = "PING #{dest} #{time_s} (#{ping_output_file})"
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
    
ping_output_file = ARGV[0]

points = load_values(ping_output_file)

title = get_title(ping_output_file)

svgContent = svg(width, height, points, title)

puts svgContent
