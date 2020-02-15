module Soda
  module Queues
    class Registry
      include Enumerable

      def initialize
        @entries = []
        @mutex   = Mutex.new
      end

      def each(&block)
        entries.each(&block)
      end

      def register(name, url = nil, **options)
        if include?(name)
          replace(name, url, **options)
        else
          mutex.synchronize do
            queue = Soda::Queue.new(name, url, options)
            queue.tap do
              entries << queue
            end
          end
        end
      end

      def include?(name)
        entries.any? do |entry|
          entry.name == name
        end
      end

      def index(name)
        entries.find_index do |entry|
          entry.name == name
        end
      end

      def replace(name, url = nil, **options)
        queue = Soda::Queue.new(name, url, options)
        queue.tap do
          entries[index(name)] = queue
        end
      end

      def deregister(name, *)
        mutex.synchronize do
          entries.delete_if do |entry|
            entry.name == name
          end
        end
      end

      # Try to find a registered queue. If one is not registered, then create a
      # new one for the specified name (with no specified URL or options).
      def select(name)
        entry = entries.detect { |ent| ent.name == name }
        (entry = register(name)) if entry.nil?

        entry
      end

      # TODO: improve error
      def default!
        entries.first or raise
      end

      private

      attr_reader :entries, :mutex
    end
  end
end
