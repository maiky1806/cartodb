require_relative '../../../models/carto/permission'

module Carto
  module Api
    class UsertokenController < ::Api::ApplicationController
      ssl_required :show, :create, :update, :destroy


      def show
        if token_exists(params[:user_token])
          entry = get_token_info(params[:user_token])
          response = { :user_token => params[:user_token], :user => entry[0], :permission => entry[1]}
          render_jsonp(response)
        else
          head(404)
        end
      end

      def create
        if Carto::Permission.has_write_permission?(params[:permission])
          permission = 'rw'
        else
          permission = 'r'
        end
        token = [*('a'..'z'),*('0'..'9')].shuffle[0,30].join
        save_token(token, current_user.username, permission)
        response = { :user_token => token, :user => current_user.username, :permission => permission}
        render_jsonp(response)
      rescue => e
        render_jsonp({ errors: [e.message] }, 400)
      end


      def update
        if token_exists(params[:user_token])
          if params[:permission]
            if Carto::Permission.has_write_permission?(params[:permission])
              permission = 'rw'
            elsif Carto::Permission.has_read_permission?(params[:permission])
              permission = 'r'
            else
              head(400)
            end
            save_token(params[:user_token], current_user.username, permission)
          else
            head(400)
          end
          show
        else
          head(404)
        end
      rescue => e
        render_jsonp({ errors: [e.message] }, 400)
      end

      def destroy
        delete_token(params[:user_token])
        render_jsonp({"success" => true})
      rescue => e
        render_jsonp({ errors: [e.message] }, 400)
      end

      def save_token(token, user, permission)
        $users_metadata.HMSET(token, "user", user, "permission", permission)
      end

      def get_token_info(token)
        $users_metadata.HMGET(token, "user", "permission")
      end

      def delete_token(token)
        $users_metadata.HDEL(token, "user", "permission")
      end

      def token_exists(token)
        !$users_metadata.HGET(token, "user").nil?
      end
    end
  end
end
