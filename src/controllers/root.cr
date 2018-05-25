class Root < Application
  base "/"

  def index
    head :misdirected_request
  end

  def show
    head :misdirected_request
  end
end
