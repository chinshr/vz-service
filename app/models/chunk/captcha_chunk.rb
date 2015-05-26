# CAPTCHA = (C)ompletely (A)utomated (P)ublic (T)uring Test to tell
# (C)omputers and (H)umans (A)part
class Chunk::CaptchaChunk < ::Chunk
  after_commit :create_hit

  protected

  def create_hit
    MechanicalTurk.create_hit(self)
  end
end