require "test_helper"

class RepairPhotosTest < ActionDispatch::IntegrationTest
  PNG = Rails.root.join("db/seeds/black_bike.png")

  setup do
    customer = Customer.create!(name: "Test", phone: "555")
    @bike = Bike.create!(make: "Giant", model: "Escape", color: "Blue", serial_number: "SN-T-1", customer: customer)
    @repair = RepairOrder.create!(bike: @bike, promised_on: Date.current + 2)
  end

  def upload(path = PNG, type = "image/png")
    Rack::Test::UploadedFile.new(path, type)
  end

  test "edit form adds photos and keeps them when saved without a file" do
    patch repair_order_path(@repair), params: { repair_order: { intake_photos: [ upload, upload ] } }
    assert_redirected_to repair_order_path(@repair)
    assert_equal 2, @repair.reload.intake_photos.count

    patch repair_order_path(@repair), params: { repair_order: { status: "dropped_off", intake_photos: [ "" ] } }
    assert_equal 2, @repair.reload.intake_photos.count

    patch repair_order_path(@repair), params: { repair_order: { intake_photos: [ upload ] } }
    assert_equal 3, @repair.reload.intake_photos.count
  end

  test "forms and pages render with and without photos" do
    get new_repair_order_path
    assert_select "input[type=file][multiple][accept]"
    assert_select "trix-editor"
    get repair_order_path(@repair)
    assert_match "No intake photos", response.body
    assert_match "No diagnosis yet", response.body
    @repair.intake_photos.attach(io: File.open(PNG), filename: "a.png", content_type: "image/png")
    get edit_repair_order_path(@repair)
    assert_select "form[action=?]", repair_order_intake_photo_path(@repair, @repair.intake_photos.first)
    get repair_order_path(@repair)
    assert_select "img[alt*=Giant]"
  end

  test "a refused upload attaches nothing, including the valid files" do
    @repair.intake_photos.attach(io: File.open(PNG), filename: "a.png", content_type: "image/png")
    pdf = Tempfile.new([ "bad", ".pdf" ]).tap { |f| f.write("%PDF-1.4 hello"); f.flush }
    patch repair_order_path(@repair), params: { repair_order: { intake_photos: [ upload, upload(pdf.path, "application/pdf") ] } }
    assert_response :unprocessable_entity
    assert_select ".invalid-feedback", /\.pdf/
    assert_equal 1, @repair.reload.intake_photos.count
  end

  test "svg and oversized files are refused" do
    svg = Tempfile.new([ "x", ".svg" ]).tap { |f| f.write('<svg xmlns="http://www.w3.org/2000/svg"/>'); f.flush }
    patch repair_order_path(@repair), params: { repair_order: { intake_photos: [ upload(svg.path, "image/svg+xml") ] } }
    assert_response :unprocessable_entity

    big = Tempfile.new([ "big", ".png" ]).tap { |f| f.binmode; f.write(File.binread(PNG)); f.write("\0".b * 11.megabytes); f.flush }
    patch repair_order_path(@repair), params: { repair_order: { intake_photos: [ upload(big.path) ] } }
    assert_response :unprocessable_entity
    assert_select ".invalid-feedback", /10 MB/
    assert_equal 0, @repair.reload.intake_photos.count
  end

  test "removing one photo purges its rows and destroying a repair leaves nothing" do
    2.times { @repair.intake_photos.attach(io: File.open(PNG), filename: "a.png", content_type: "image/png") }
    photo = @repair.intake_photos.first
    assert_difference [ "ActiveStorage::Attachment.count", "ActiveStorage::Blob.count" ], -1 do
      delete repair_order_intake_photo_path(@repair, photo)
    end
    assert_response :see_other
    @repair.update!(diagnosis: "<div>x</div>")
    delete repair_order_path(@repair)
    assert_equal 0, ActiveStorage::Attachment.count
    assert_equal 0, ActiveStorage::Blob.count
    assert_equal 0, ActionText::RichText.count
  end

  test "script in a diagnosis is saved and not rendered" do
    patch repair_order_path(@repair), params: { repair_order: { diagnosis: '<script>alert(1)</script><img src=x onerror="alert(2)"><b>ok</b>' } }
    get repair_order_path(@repair)
    assert_select "script", text: /alert/, count: 0
    assert_select "[onerror]", count: 0
    assert_select "b", "ok"
    get repair_orders_path
    assert_select "[onerror]", count: 0
  end

  test "query counts do not grow with the data" do
    count = ->(path) { n = 0; cb = ->(*, payload) { n += 1 unless payload[:name] == "SCHEMA" }
      ActiveSupport::Notifications.subscribed(cb, "sql.active_record") { get path }; n }
    add = -> { r = RepairOrder.create!(bike: @bike, promised_on: Date.current + 2, diagnosis: "<div><b>d</b></div>")
      2.times { r.intake_photos.attach(io: File.open(PNG), filename: "a.png", content_type: "image/png") } }
    2.times { add.() }
    before = [ repair_orders_path, bike_path(@bike), repair_order_path(RepairOrder.last) ].map { |path| count.(path) }
    6.times { add.() }
    after = [ repair_orders_path, bike_path(@bike), repair_order_path(RepairOrder.last) ].map { |path| count.(path) }
    assert_equal before, after
  end
end
