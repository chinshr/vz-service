class Document::Response::Word
  include Model::Virtus::ActiveModel

  attribute :i, String, default: :secure_random_id, lazy: true
  attribute :p, Integer
  attribute :c, Float
  attribute :s, Float
  attribute :e, Float
  attribute :w, String
  attribute :m, String

  # alias methods

  def id; i; end
  def id=(value); self.i = value; end
  def position; p; end
  def position=(value); self.p = value; end
  def confidence; c; end
  def confidence=(value); self.c = value; end
  def start_time; s; end
  def start_time=(value); self.s = value; end
  def end_time; e; end
  def end_time=(value); self.e = value; end
  def word; w; end
  def word=(value); self.w = value; end
  def meta; m; end
  def meta=(value); self.m = value; end

  def secure_random_id
    SecureRandom.hex(5)
  end
end
