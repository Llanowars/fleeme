class WebhooksController < ApplicationController
  include Answer
  # Ici il faut annuller la vérification des tokens qui protège toute app rails d' attaques csrf
  # Les deux lignes suivantes ont le même effet
  protect_from_forgery except: :receive
  skip_before_filter :verify_authenticity_token

  # Typeform attend une réponse de notre controlleur pour valider la route
  # set_data permet de valider que le json contient des informations
  before_action :set_data, only: [ :ugc, :user ]

  # Update l'user avec les infos récupérées par typeform
  def user
    p @data
    @answers = @data["form_response"]["answers"]
    p @answers
    @id = @data["form_response"]["hidden"]["id"].to_i
    @user = User.find(@id)
    @infos = get_user_infos(@answers)
    @user.firstname = @infos["28860463"]
    @user.lastname = @infos["28860464"]
    @user.email = @infos["28860465"]
    @user.save
    render nothing: true
  end

  # Crée un Unsub pour le service UGC, Update également l' User
  def ugc
    p @answers = get_ugc_infos(@data["form_response"]["answers"])
    @id = @data["form_response"]["hidden"]["id"].to_i
    @user = User.find(@id)
    @user.address = @answers["25424220"]
    @user.zipcode = @answers["29092897"]
    @user.city = @answers["25424218"]
    @user.save
    @service = @data["form_response"]["hidden"]["service"].to_i
    @unsub_id = @data["form_response"]["hidden"]["unsub"].to_i
    @unsub = Unsub.find(@unsub_id)
    @unsub.service_id = @service
    @unsub.form_complete = @data
    @unsub.price_cents = 700
    @unsub.sku = 'ugc'
    @unsub.details = parse_ugc(@data["form_response"]["answers"])
    @unsub.save
    render nothing: true
  end

  private

  def set_data
    request.headers['Content-Type'] == 'application/json' ? @data = JSON.parse(request.body.read) : @data = params.as_json
    render nothing: true, status: 200 if @data == {}
  end

  def get_user_infos(array)
    hash = {}
    array.each do |q|
      types = ['text', 'email']
      type = q['type']
      hash[q["field"]["id"]] = q[type] if types.include?(type)
    end
    return hash
  end

  def get_ugc_infos(array)
    hash = {}
    array.each do |q|
      types = ['text', 'email']
      type = q['type']
      if types.include?(type)
        hash[q["field"]["id"]] = q[type]
      elsif type == 'choice'
        hash[q['field']['id']] = q["choice"]
      end
    end
    return hash
  end
end
