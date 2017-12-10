class Lock
  def initialize
    @locked = false
  end

  def acquire
    if !@locked
      return @locked = true
    end

    false
  end

  def release
    @locked = false
  end

  def locked?
    @locked
  end

  def unlocked?
    !@locked
  end

  alias free? unlocked?
end
