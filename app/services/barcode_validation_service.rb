class BarcodeValidationService
  # Validates EAN-13 barcodes and determines if they represent valid ISBNs

  def self.valid_ean13?(gtin)
    new(gtin).valid_ean13?
  end

  def self.valid_isbn?(gtin)
    new(gtin).valid_isbn?
  end

  def self.valid_barcode?(gtin)
    new(gtin).valid_barcode?
  end

  def initialize(gtin)
    @gtin = gtin.to_s.strip
  end

  # Check if the EAN-13 has a valid format and check digit
  def valid_ean13?
    return false unless basic_format_valid?
    valid_check_digit?
  end

  # Check if the EAN-13 represents a valid ISBN (starts with 978 or 979)
  def valid_isbn?
    return false unless valid_ean13?
    isbn_prefix?
  end

  # Combined validation - true if it's a valid EAN-13 (accepts all product types, not just books)
  def valid_barcode?
    valid_ean13?
  end

  private

  def basic_format_valid?
    @gtin.match?(/\A\d{13}\z/)
  end

  def isbn_prefix?
    @gtin.start_with?("978", "979")
  end

  # EAN-13 check digit validation using modulo 10 weighted sum
  def valid_check_digit?
    return false unless basic_format_valid?

    digits = @gtin.chars.map(&:to_i)
    check_digit = digits.pop

    # Calculate weighted sum (multiply odd positions by 1, even positions by 3)
    weighted_sum = digits.each_with_index.sum do |digit, index|
      weight = index.even? ? 1 : 3
      digit * weight
    end

    # Check digit should make the total sum divisible by 10
    calculated_check_digit = (10 - (weighted_sum % 10)) % 10
    check_digit == calculated_check_digit
  end
end
