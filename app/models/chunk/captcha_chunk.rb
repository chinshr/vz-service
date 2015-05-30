# CAPTCHA = (C)ompletely (A)utomated (P)ublic (T)uring Test to tell
# (C)omputers and (H)umans (A)part
class Chunk::CaptchaChunk < ::Chunk
  after_commit :create_hit

  protected

  def create_hit
    MechanicalTurk.create_hit(self)
  end

  # Override superclass
  def after_add_chunk_segment(segment)
    super
    if new_record?
      segment.signal_assign_chunk_track!
    end
  end
end