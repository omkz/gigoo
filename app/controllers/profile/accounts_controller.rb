module Profile
  class AccountsController < ApplicationController
    def edit
      @user = Current.user
    end

    def update
      @user = Current.user

      if @user.update(account_params)
        redirect_to profile_path, notice: "Account was updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

    def account_params
      params.require(:user).permit(:first_name, :last_name)
    end
  end
end
