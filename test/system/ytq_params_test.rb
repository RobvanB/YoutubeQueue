require "application_system_test_case"

class YtqParamsTest < ApplicationSystemTestCase
  setup do
    @ytq_param = ytq_params(:one)
  end

  test "visiting the index" do
    visit ytq_params_url
    assert_selector "h1", text: "Ytq Params"
  end

  test "creating a Ytq param" do
    visit ytq_params_url
    click_on "New Ytq Param"

    fill_in "Last Date", with: @ytq_param.last_date
    click_on "Create Ytq param"

    assert_text "Ytq param was successfully created"
    click_on "Back"
  end

  test "updating a Ytq param" do
    visit ytq_params_url
    click_on "Edit", match: :first

    fill_in "Last Date", with: @ytq_param.last_date
    click_on "Update Ytq param"

    assert_text "Ytq param was successfully updated"
    click_on "Back"
  end

  test "destroying a Ytq param" do
    visit ytq_params_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Ytq param was successfully destroyed"
  end
end
