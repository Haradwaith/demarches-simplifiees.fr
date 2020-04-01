class ChampPolicy < ApplicationPolicy
  class Scope < ApplicationScope
    def resolve
      if user.blank?
        return scope.none
      end

      # (The join must be the same for all elements of the WHERE clause)
      joined_scope = scope
        .joins('LEFT OUTER JOIN dossiers ON dossiers.id = champs.dossier_id')
        .joins('LEFT OUTER JOIN invites ON invites.dossier_id = dossiers.id')
        .joins('LEFT OUTER JOIN groupe_instructeurs ON groupe_instructeurs.id = dossiers.groupe_instructeur_id')
        .joins('LEFT OUTER JOIN assign_tos ON assign_tos.groupe_instructeur_id = groupe_instructeurs.id')
        .joins('LEFT OUTER JOIN instructeurs ON instructeurs.id = assign_tos.instructeur_id')

      # Users can access public champs on their own dossiers.
      resolved_scope = joined_scope
        .where('dossiers.user_id': user.id, private: false)

      # Invited users can access public champs on dossiers they are invited to
      invite_clause = joined_scope
        .where('invites.user_id': user.id, private: false)
      resolved_scope = resolved_scope.or(invite_clause)

      if instructeur.present?
        # Additionnaly, instructeurs can access private champs
        # on dossiers they are allowed to instruct.
        instructeur_clause = joined_scope
          .where('instructeurs.id': instructeur.id, private: true)
        resolved_scope = resolved_scope.or(instructeur_clause)
      end

      resolved_scope
    end
  end
end
