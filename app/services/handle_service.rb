require 'handle'

class HandleService
  def initialize(generic_work)
    @generic_work = generic_work

    @mint_handles = true unless Rails.configuration.x.handle["mint"] == false
    @prefix       = Rails.configuration.x.handle["prefix"]
    @index        = Rails.configuration.x.handle["index"].to_i
    @adminhdl     = Rails.configuration.x.handle["admin_handle"]
    @admpriv      = Rails.configuration.x.handle["admin_priv_key"]
    @admpass      = Rails.configuration.x.handle["admin_passphrase"]
    @url          = Rails.configuration.x.handle["url"]
  end

  def mint
    if minting_disabled?
      Rails.logger.debug "Handle was not created for file #{@generic_work.id} because minting is disabled."
    elsif handle_needed?
      create_handle!
    else
      Rails.logger.debug "Handle not created. File #{@generic_work.id} does not need a handle."
    end

    @generic_work.handle
  end

  # Begin private methods
  private

  def minting_disabled?
    !@mint_handles
  end

  def handle_needed?
    @generic_work.handle.blank? && file_is_visible? # && file_has_no_active_imports?
  end

  def modify_handle!
    begin
      # Set up an authenticated connection
      conn = Handle::Connection.new(@adminhdl, @index, @admpriv, @admpass)

      # Get the handle but remove the link
      handle = @generic_work.handle.last
      conn.delete_handle(handle)

      # Create an empty record
      record = conn.create_record(handle)

      # add field
      url =  "#{@url}#{@generic_work.id}"
      record.add(:URL, url).index = 2
      record << Handle::Field::HSAdmin.new(@adminhdl)

      # Manipulate permissions
      record.last.perms.public_read = false
      record.save
      Rails.logger.info "The handle #{handle} was successfully created for file #{@generic_work.id}"

    rescue Handle::HandleError => e
      Rails.logger.error "ERROR! A new handle could not be minted for file #{@generic_work.id}. The exception was:"
      Rails.logger.error "#{e.class}: #{e.message}"
    end
  end

  def create_handle!
    # Create handle string
    handle = "#{@prefix}/#{SecureRandom.uuid}"

    begin
      # Set up an authenticated connection
      conn = Handle::Connection.new(@adminhdl, @index, @admpriv, @admpass)

      # Create an empty record
      record = conn.create_record(handle)

      # add field
      url =  "#{@url}#{@generic_work.id}"
      record.add(:URL, url).index = 2
      record << Handle::Field::HSAdmin.new(@adminhdl)

      # Manipulate permissions
      record.last.perms.public_read = false

      record.save
      @generic_work.handle = [handle]
      @generic_work.save
      Rails.logger.info "The handle #{handle} was successfully created for file #{@generic_work.id}"

    rescue Handle::HandleError => e
      Rails.logger.error "ERROR! A new handle could not be minted for file #{@generic_work.id}. The exception was:"
      Rails.logger.error "#{e.class}: #{e.message}"
    end
  end

  def file_is_visible?
    @generic_work.visibility != Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
  end

  def file_has_no_active_imports?
    Import.with_imported_file(@generic_work).where.not(status: Import.statuses[:final]).empty?
  end
end
