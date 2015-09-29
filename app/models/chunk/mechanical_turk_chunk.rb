require 'amatch'

class Chunk::MechanicalTurkChunk < ::Chunk
  SOURCE_CHUNK_SCORE_THRESHOLD    = 0.8
  REFERENCE_CHUNK_SCORE_THRESHOLD = 0.95

  belongs_to :turkee_task, class_name: "Turkee::TurkeeTask", foreign_key: :turkee_task_id

  class << self

    # Create hit based on a chunk (a PocketsphinxChunk)
    # Example title: "Transcribe up to 25 Seconds of %{language} audio to text - Earn up to $0.12 per HIT!"
    # Sandbox: https://requestersandbox.mturk.com/mturk/manageHITs
    def create_hit(chunk, options = {})
      raise "Can only create HIT based on a chunk" unless chunk.is_a?(Chunk)
      qualifications = {}
      params   = {}
      options  = options.reverse_merge({
        form_url: hit_form_url(chunk), frame_height: 250,
        keywords: "transcribe, transcription, media, audio, #{I18n.humanized_locale_language(chunk.locale)}, type, typist, caption, subtitle"
      })
      reward   = 0.01        # in dollars
      lifetime = 15.minutes  # in seconds
      duration = 5.minutes   # in seconds
      num_assignments = 1

      task = Turkee::TurkeeTask.create_hit(
        turk_host,
        hit_title(chunk), hit_description(chunk),
        self.name, num_assignments, reward, lifetime, duration,
        qualifications, params, options)

      chunk.update_attributes({turkee_task_id: task.id}) if task.valid?
      task
    end

    def process_hits
      tasks = Turkee::TurkeeTask.where(complete: false)
      tasks.find_each do |task|
        Turkee::TurkeeTask.process_hits(task)
        chunks = self.where(turkee_task_id: task.id)
        process_data(chunks)
      end
    end

    # callback
    # * approve tasks that have somewhat an acceptable score, fuzzy match >.3?
    def hit_complete(turkee_task)
      if chunk = Chunk::MechanicalTurkChunk.find_by(turkee_task_id: turkee_task.id)
        chunk.update_attributes(processing_status: ::Chunk::STATES[:transcribed])
      end
    end

    # callback
    # * set status to transcription error for all chunks belonging to this task
    def hit_expired(turkee_task)
      if chunk = Chunk::MechanicalTurkChunk.find_by(turkee_task_id: turkee_task.id)
        chunk.update_attributes(processing_status: Chunk::STATES[:transcription_error])
      end
    end

    def extract_truth(full_text, reference_texts)
      full_text = full_text.dup
      Array.wrap(reference_texts).each do |reference_text|
        left, right = match_boundary(full_text, reference_text)
        full_text.gsub!(Regexp.new(full_text.slice(left..right), Regexp::IGNORECASE), '')
      end
      full_text.squish
    end

    def match_boundary(full_text, reference_text)
      full_text, reference_text = full_text.dup.downcase, reference_text.dup.downcase
      li, ri = 0, full_text.length - 1
      ps     = 1.0
      (0..full_text.length).each do |index|
        cs  = full_text[li..ri].levenshtein_similar(reference_text)
        fls = full_text[(li + 1)..ri].levenshtein_similar(reference_text)
        frs = full_text[li..(ri -1)].levenshtein_similar(reference_text)

        if fls > cs
          li += 1
        elsif frs > cs
          ri -= 1
        else (fls < cs || frs < cs) && cs > ps
          return li, ri
        end
        ps = cs
      end
      return 0, 0
    end

    def match_confidence(full_text, reference_texts)
      confidence = 0.0
      reference_texts = Array.wrap(reference_texts)
      reference_texts.each do |reference_text|
        m = Amatch::LongestSubsequence.new(full_text.downcase)
        match_count = m.match(reference_text.downcase)
        confidence  += [1.0, (match_count / reference_text.length.to_f)].min
      end
      confidence / reference_texts.count.to_f
    end

    protected

    def hit_form_url(document)
      app  = ActionDispatch::Integration::Session.new(Rails.application)
      path = app.send :new_web_mechanical_turk_document_chunk_path, document.uid
      url  = turk_host + path
    end

    def turk_host
      Rails.env.production? ? "https://www.voyz.es" : "https://localhost:3000"
    end

    def hit_title(document)
      I18n.t("activerecord.models.mechanical_turk.create_hit_title", :language => I18n.humanized_locale_language(document.locale))
    end

    def hit_description(document)
      I18n.t("activerecord.models.mechanical_turk.create_hit_description")
    end

    def process_data(chunks)
    end

  end # class

  def approve?
    result = false
    if is_captcha_based?
      confidence = captcha_confidence
      if confidence > SOURCE_CHUNK_SCORE_THRESHOLD
        extracted_text = extract_truth
        update_columns({text: extracted_text, score: confidence})
        result = true
        promote_to_sibling_of source_chunk, {text: extracted_text, score: confidence}
      end
    else
      result = !text.blank?
    end
    result
  end

  def extract_truth
    self.class.extract_truth(text, reference_chunks.map(&:text))
  end

  def assignment
    Turkee::TurkeeImportedAssignment.where(result_id: self.id)
  end

  protected

  def captcha_confidence
    confidence = 0.0
    reference_chunks.each do |reference_chunk|
      m = Amatch::LongestSubsequence.new(text.downcase)
      match_count = m.match(reference_chunk.text.downcase)
      confidence  += match_count / reference_chunk.text.downcase.length.to_f
    end
    confidence / reference_chunks.count.to_f
  end

  # Good quality reference chunks
  def reference_chunks
    @reference_chunks ||= begin
      document.chunks.none_of_types(self.class.name).score_gteq(REFERENCE_CHUNK_SCORE_THRESHOLD)
    end
  end

  # Chunk that is under test
  def source_chunk
    @source_chunk ||= begin
      document.chunks.none_of_types(self.class.name).where("documents.id NOT IN (?)", reference_chunks.map(&:id)).first
    end
  end

  private

  def is_captcha_based?
    document && document.is_a?(Chunk::CaptchaChunk)
  end

  # Promotes the current chunk to one equal to the given one, e.g. source chunk
  def promote_to_sibling_of(sibling, chunk_attributes = {})
    previous_parent       = document
    self.document         = sibling.document
    self.track            = sibling.track
    self.position         = sibling.position
    self.offset           = sibling.offset
    self.locale           = sibling.locale
    self.ingest_id        = sibling.ingest_id
    self.ingest_iteration = sibling.ingest_iteration
    self.turkee_task_id   = previous_parent.turkee_task_id
    save
  end

  def assign_root_document
    if document.is_a?(Chunk) && root = document.document
      self.document = root
    end
  end
end