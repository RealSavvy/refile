require "refile"
require "refile/rails/attachment_helper"

module Refile
  # @api private
  class Engine < Rails::Engine
    initializer "refile.setup", before: :load_environment_config do
      Refile.store ||= Refile::Backend::FileSystem.new(Rails.root.join("tmp/uploads/store").to_s)
      Refile.cache ||= Refile::Backend::FileSystem.new(Rails.root.join("tmp/uploads/cache").to_s)

      ActiveSupport.on_load :active_record do
        require "refile/attachment/active_record"
      end

      ActionView::Base.send(:include, Refile::AttachmentHelper)
      ActionView::Helpers::FormBuilder.send(:include, AttachmentHelper::FormBuilder)
    end

    initializer "refile.app" do
      Refile.logger = Rails.logger
      Refile.app = Refile::App.new
    end
  end
end

# Add in missing methods for file uploads in Rails < 4
ActionDispatch::Http::UploadedFile.class_eval do
  unless instance_methods.include?(:eof?)
    def eof?
      @tempfile.eof?
    end
  end

  unless instance_methods.include?(:close)
    def close
      @tempfile.close
    end
  end
end
