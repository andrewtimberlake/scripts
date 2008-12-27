require 'test_helper'

class <%= controller_class_name %>ControllerTest < ActionController::TestCase
  def setup
    #TODO: Create an entry for testing here (or in a fixture, or with a factory like Factory Girl)
    <%= class_name %>.create()
  end

  context "on GET to :index" do
    setup {
       get :index
    }

    should_respond_with :success
    should_assign_to :<%= table_name %>, :equals => "@<%= table_name %>"
    should_not_set_the_flash
    should_render_template :index
  end

  context "on GET to :new" do
    setup {
      get :new
    }

    should_respond_with :success
    should_assign_to :<%= singular_name %>, :equals => "@<%= singular_name %>"
    should_not_set_the_flash
    should_render_template :new
    should_render_a_form
  end

  context "on POST to :create" do
    context "with no data" do
      setup {
        post :create, :<%= file_name %> => {}
      }

      should_respond_with :success
      should_assign_to :<%= singular_name %>, :equals => "@<%= singular_name %>"
      should_render_template :new
      should_render_a_form
    end

    context "with data" do
      setup {
        post :create, :<%= file_name %> => {
          #TODO: fill in values for create
        }
      }

      should_respond_with 303
      should_redirect_to "@<%= singular_name %>"
      should_set_the_flash_to /successfully created/
    end
  end

  context "on GET to :show" do
    setup {
      get :show, :id => <%= class_name %>.first.id
    }

    should_respond_with :success
    should_assign_to :<%= singular_name %>, :equals => "@<%= singular_name %>"
    should_not_set_the_flash
    should_render_template :show
  end

  context "on GET to :edit" do
    setup {
      get :edit, :id => <%= class_name %>.first.id
    }

    should_respond_with :success
    should_assign_to :<%= singular_name %>, :equals => "@<%= singular_name %>"
    should_not_set_the_flash
    should_render_template :edit
    should_render_a_form
  end

  context "on PUT to :update" do
    context "with no data" do
      setup {
        post :update, :id => <%= class_name %>.first.id, :<%= file_name %> => {}
      }

      should_respond_with :success
      should_assign_to :<%= singular_name %>, :equals => "@<%= singular_name %>"
      should_render_template :edit
      should_render_a_form
    end

    context "with data" do
      setup {
        put :update, :id => <%= class_name %>.first.id, :<%= file_name %> => {
          #TODO: fill in values for update
        }
      }

      should_respond_with 303
      should_redirect_to "@<%= singular_name %>"
      should_set_the_flash_to /successfully updated/
    end
  end

  context "on DELETE to :destroy" do
    setup {
      delete :destroy, :id => <%= class_name %>.first.id
    }

    should_respond_with 303
    should_redirect_to "<%= table_name %>_url"
    should_set_the_flash_to /successfully deleted/
  end
end
