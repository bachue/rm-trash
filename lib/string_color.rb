class String
  COLORS =
  {
    "black"   => 0,
    "red"     => 1,
    "green"   => 2,
    "yellow"  => 3,
    "blue"    => 4,
    "purple"  => 5,
    "magenta" => 5,
    "cyan"    => 6,
    "white"   => 7
  }

  COLORS.each_pair do |color, value|
    define_method(color) do
      "\033[0;#{30+value}m#{self}\033[0m"
    end

    define_method("bright_#{color}") do
      "\033[1;#{30+value}m#{self}\033[0m"
    end
  end

  def bold
    "\e[1m#{self}\e[0m"
  end

  def strip_color
    gsub(/\e\[.*?(\d)+m/ , '')
  end
end