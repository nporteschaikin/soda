module Soda
  module Middleware
    class Chain
      include Enumerable

      Entry = Struct.new(:klass, :args) do
        def build
          klass.new(*args)
        end
      end

      def initialize
        @entries = []
      end

      def each
        entries.each(&:block)
      end

      def add(klass, *args)
        remove(klass)
        entries << Entry.new(klass, args)
      end

      def remove(klass)
        entries.delete_if { |entry| entry.klass == klass }
      end

      def insert_at(index, klass, *args)
        entries.insert(index, Entry.new(klass, args))
      end

      def use(*args)
        traverse(entries.dup, args) do
          yield
        end
      end

      private

      attr_reader :entries

      def traverse(copy, args)
        if copy.empty?
          yield
        else
          entry = copy.shift
          inst  = entry.klass.new(*entry.args)

          inst.call(*args) do
            traverse(copy, args) { yield }
          end
        end
      end
    end
  end
end
