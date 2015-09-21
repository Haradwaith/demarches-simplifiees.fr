class Dossier < ActiveRecord::Base
  has_one :etablissement
  has_one :entreprise
  has_one :cerfa
  has_many :pieces_justificatives
  belongs_to :procedure
  has_many :commentaires

  delegate :siren, to: :entreprise
  delegate :siret, to: :etablissement
  delegate :types_de_piece_justificative, to: :procedure

  before_create :build_default_cerfa

  after_save :build_default_pieces_justificatives, if: Proc.new { procedure_id_changed? }

  validates :mail_contact, format: { with: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/ }, unless: 'mail_contact.nil?'
  validates :nom_projet, presence: true, allow_blank: false, allow_nil: true
  validates :description, presence: true, allow_blank: false, allow_nil: true
  validates :montant_projet, presence: true, allow_blank: false, allow_nil: true
  validates :montant_aide_demande, presence: true, allow_blank: false, allow_nil: true
  validates :date_previsionnelle, presence: true, allow_blank: false,  unless: Proc.new { description.nil? }


  def retrieve_piece_justificative_by_type(type)
    pieces_justificatives.where(type_de_piece_justificative_id: type).last
  end

  def build_default_pieces_justificatives
    procedure.types_de_piece_justificative.each do |type_de_piece_justificative|
      PieceJustificative.create(type_de_piece_justificative_id: type_de_piece_justificative.id, dossier_id: id)
    end
  end

  def sous_domaine
    if Rails.env.production?
      'tps'
    else
      'tps-dev'
    end
  end

  private

  def build_default_cerfa
    build_cerfa
    true
  end

end
