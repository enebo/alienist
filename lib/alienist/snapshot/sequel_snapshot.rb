require 'sequel'

module Alienist
  class SequelSnapshot
    def initialize(db_string="jdbc:sqlite:db")
      @db = Sequel.connect(db_string)
      create_schema      
    end

    def add_instance(id, serial, class_id, bytes_following)
      @db[:instances].insert(id: id, class_id: class_id)
    end

    def add_root(*r)
    end

    def add_class(id, name, super_id, classloader_id, signers_id,
                  protection_domain_id, static_fields, fields, instance_size)
      @db[:classes].insert(id: id, name: name, super_id: super_id, 
                           classloader_id: classloader_id, 
                           signers_id: signers_id, 
                           protection_domain_id: protection_domain_id,
                           instance_size: instance_size)

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
        primary_key :id
        Int :class_id, null: false
      end

      @db.create_table(:fields) do
        primary_key :id
        Int :class_id, null: false
        String :name, null: false
        String :type, null: false
      end

      @db.create_table(:static_fields) do
        primary_key :id
        Int :class_id, null: false
        String :name, null: false
        String :type, null: false
      end
      # FIXME: need to store value and deal with heap, object_ref, and value

      @db.create_table(:classes) do
        primary_key :id
        String :name, null: false
        Int :super_id, null: false
        Int :classloader_id, null: false
        Int :signers_id, null: false
        Int :protection_domain_id, null: false
        Int :instance_size, null: false
      end
    end
  end
end
