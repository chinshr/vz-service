class Chunk::MechanicalTurkChunk < ::Chunk
  belongs_to :turkee_task, class_name: "Turkee::TurkeeTask", foreign_key: :turkee_task_id
  before_save :copy_sibling_attributes, :assign_root_document, on: :create

  class << self

    # Create hit based on a chunk (a PocketsphinxChunk)
    # Example title: "Transcribe up to 25 Seconds of %{language} audio to text - Earn up to $0.12 per HIT!"
    # Sandbox: https://requestersandbox.mturk.com/mturk/manageHITs
    def create_hit(chunk, options = {})
      raise "Can only create HIT based on a chunk" unless chunk.is_a?(Chunk)
      qualifications = {}
      params   = {}
      options  = options.reverse_merge({form_url: hit_form_url(chunk),
        frame_height: 250,
        keywords: "transcribe, transcription, media, audio, English, type, typist, caption, subtitle"})
      reward   = 0.01        # in dollars
      lifetime = 15.minutes  # in seconds
      duration = 2.minutes   # in seconds
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
      I18n.t("activerecord.models.mechanical_turk.create_hit_title", :language => 'English')
    end

    def hit_description(document)
      I18n.t("activerecord.models.mechanical_turk.create_hit_description")
    end

    def process_data(chunks)
    end

  end # end class

  def approve?
    # Make sure we can defer approval until we have collected all assignments.
    # E.g.
    # return [true, "all good"] -> accept with reason 'all good'
    # return [false, "garbage input"] -> reject with reason 'garbage input'
    # return [nil, "deferred"] -> defer, neither accept nor reject
    !text.blank?
  end

  def assignment
    Turkee::TurkeeImportedAssignment.where(result_id: self.id)
  end

  private

  def copy_sibling_attributes
    if document.is_a?(Chunk) && sibling = document
      self.position         = sibling.position
      self.offset           = sibling.offset
      self.duration         = sibling.duration
      self.start_at         = sibling.start_at
      self.end_at           = sibling.end_at
      self.turkee_task_id   = sibling.turkee_task_id
      self.locale           = sibling.locale
      self.ingest_id        = sibling.ingest_id
      self.ingest_iteration = sibling.ingest_iteration
      self.track            = sibling.track
    end
  end

  def assign_root_document
    if document.is_a?(Chunk) && root = document.document
      self.document = root
    end
  end
end