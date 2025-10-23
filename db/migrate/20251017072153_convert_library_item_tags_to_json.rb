class ConvertLibraryItemTagsToJson < ActiveRecord::Migration[8.0]
  def change
    # No schema change needed - tags column remains string type
    # Rails serialize will handle JSON encoding/decoding automatically
  end
end
