module Model::Uid
  UID_LENGTH = 40
  
  def self.included(base)
    base.send :extend, ClassMethods
    base.send :include, InstanceMethods
    
    base.class_eval do
      before_validation :generate_uid
    end
  end

  module ClassMethods
    # E.g. random_string(5, "a-z, 0-9")
    def random_string(len = 10, set = nil)
      chars = parse_characters_set(set) || [('a'..'z'), ('A'..'Z'), ('0'..'9')].map {|i| i.to_a}.flatten
      String.new.tap {|s| 1.upto(len) {|i| s << chars[rand(chars.size - 1)]}} unless chars.empty?
    end

    private

    # E.g. a-z, A-Z
    def parse_characters_set(definition)
      definition.split(",").inject([]) do |a, e|
        e.strip!
        if e.match(/^(.)-(.)$/)
          a += ($1).upto($2).to_a
        elsif e.match(/^(.)$/)
          a << $1
        end
      end unless definition.blank?
    end
  end

  module InstanceMethods
    def generate_uid
      begin; self.uid = self.class.random_string(self.class::UID_LENGTH); end while self.class.where(:uid => uid).present?
    end
  end
end