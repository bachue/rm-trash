class String
  class << self
    attr_accessor :colorful
  end
  self.colorful = true

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
      if String.colorful
        "\033[0;#{30+value}m#{self}\033[0m"
      else
        self
      end
    end

    define_method("bright_#{color}") do
      if String.colorful
        "\033[1;#{30+value}m#{self}\033[0m"
      else
        self
      end
    end
  end

  def bold
    if String.colorful
      "\e[1m#{self}\e[0m"
    else
      self
    end
  end

  def underline
    if String.colorful
      "\033[4m#{self}\033[0m"
    else
      self
    end
  end
end