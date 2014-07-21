require 'alienist/snapshot/base_snapshot'
require 'sequel'

module Alienist
  module Snapshot
    class SequelSnapshot < BaseSnapshot
      attr_reader :db

      def initialize(db_string="jdbc:h2:./ddb;create=true")
        super()
        #def initialize(db_string="jdbc:sqlite:db")
        @db = Sequel.connect(db_string)
        create_schema      
      end

      def add_instance(id, serial, class_id, bytes_following)
        $ps1.call(id: id, class_id: class_id)
        #      @db[:instances].insert(id: id, class_id: class_id)
      end

      def add_root(*r)
      end

      def add_class(id, name, super_id, classloader_id, signers_id,
                    protection_domain_id, instance_size)
        #      begin
        # @db[:classes].insert(id: id, name: name, super_id: super_id, 
        $ps2.call(id: id, name: name, super_id: super_id, 
                  classloader_id: classloader_id, 
                  signers_id: signers_id, 
                  protection_domain_id: protection_domain_id,
                  instance_size: instance_size)
        # rescue Sequel::DatabaseError
        #   puts "ID: #{id}, SID: #{super_id}, CID: #{classloader_id}"
        #   puts "SGN_ID: #{signers_id}, PDID: #{protection_domain_id}"
        #   puts "IS: #{instance_size}"
        #      end

        # static_fields.each do |field|
        #   @db[:static_fields].insert(id: field.field.id, class_id: id,
        #                              name: field.field.name,
        #                              type: field.field.type)
        # end

        # fields.each do |field|
        #   @db[:fields].insert(id: field.id, class_id: id,
        #                       name: field.name, type: field.type)
        # end
      end


      def create_schema
        @db.drop_table :classes if @db.table_exists?(:classes)
        @db.drop_table :fields if @db.table_exists?(:fields)
        @db.drop_table :static_fields if @db.table_exists?(:static_fields)
        @db.drop_table :instances if @db.table_exists?(:instances)

        @db.create_table(:instances) do
          Bignum :id, primary_key: true
          Bignum :class_id, null: false
        end

        $ps1 = @db[:instances].prepare(:insert, :insert_p, :id=>:$id, :class_id=>:$class_id)

        @db.create_table(:fields) do
          Bignum :id, primary_key: true
          Bignum :class_id, null: false
          String :name, null: false
          String :type, null: false
        end

        @db.create_table(:static_fields) do
          Bignum :id, primary_key: true
          Bignum :class_id, null: false
          String :name, null: false
          String :type, null: false
        end
        # FIXME: need to store value and deal with heap, object_ref, and value

        @db.create_table(:classes) do
          Bignum :id, primary_key: true
          String :name, null: false
          Bignum :super_id, null: false
          Bignum :classloader_id, null: false
          Bignum :signers_id, null: false
          Bignum :protection_domain_id, null: false
          Bignum :instance_size, null: false
        end

        $ps2 = @db[:classes].prepare(:insert, :insert_p, :id =>:$id, :name => :$name, :super_id => :$super_id, :classloader_id =>:$classloader_id, :signers_id => :$signers_id, :protection_domain_id =>:$protection_domain_id, :instance_size =>:$instance_size)

      end
    end
  end
end
