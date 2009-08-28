
class File
  # Seek to the end of the file
  def seek_end
    seek(0, IO::SEEK_END)
  end
  
  # Read a chunk of data and then move the file pointer backwards.
  #
  # Calling this function multiple times will return new data and traverse the file backwards.
  #
  def read_reverse(length)
    offset = tell
    
    if offset == 0
      return nil
    end
    
    start = [0, offset-length].max
    
    seek(start, IO::SEEK_SET)
    
    buf = read(offset-start)
    
    seek(start, IO::SEEK_SET)
    
    return buf
  end
  
  REVERSE_BUFFER_SIZE = 128

  # This function is very similar to gets but it works in reverse.
  #
  # You can use it to efficiently read a file line by line backwards.
  # 
  # It returns nil when there are no more lines.
  def reverse_gets(sep_string=$/)
    end_pos = tell
    
    offset = nil
    buf = ""
    
    while offset == nil
      chunk = read_reverse(REVERSE_BUFFER_SIZE)
      return (buf == "" ? nil : buf) if chunk == nil
      
      buf = chunk + buf
      
      offset = buf.rindex(sep_string)
    end
    
    line = buf[offset...buf.size].sub(sep_string, "")
    
    seek((end_pos - buf.size) + offset, IO::SEEK_SET)
    
    return line
  end
  
  # Similar to each_line but works in reverse. Don't forget to call
  # seek_end before you start!
  def reverse_each_line(sep_string=$/, &block)
    line = reverse_gets(sep_string)
    
    while line != nil
      yield line
      
      line = reverse_gets(sep_string)
    end
  end
end
