require 'test_helper'

class YtqParamsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ytq_param = ytq_params(:one)
  end

  test "should get index" do
    get ytq_params_url
    assert_response :success
  end

  test "should get new" do
    get new_ytq_param_url
    assert_response :success
  end

  test "should create ytq_param" do
    assert_difference('YtqParam.count') do
      post ytq_params_url, params: { ytq_param: { last_date: @ytq_param.last_date } }
    end

    assert_redirected_to ytq_param_url(YtqParam.last)
  end

  test "should show ytq_param" do
    get ytq_param_url(@ytq_param)
    assert_response :success
  end

  test "should get edit" do
    get edit_ytq_param_url(@ytq_param)
    assert_response :success
  end

  test "should update ytq_param" do
    patch ytq_param_url(@ytq_param), params: { ytq_param: { last_date: @ytq_param.last_date } }
    assert_redirected_to ytq_param_url(@ytq_param)
  end

  test "should destroy ytq_param" do
    assert_difference('YtqParam.count', -1) do
      delete ytq_param_url(@ytq_param)
    end

    assert_redirected_to ytq_params_url
  end
end
