class User < ApplicationRecord
  enum kinds: {'student': 0, 'teacher': 1, 'student_teacher': 2}

  # Create dynamic methods -> student?, teacher?, student_teacher?
  User.kinds.each do |role, value|
    define_method("#{role}?") do
      kind == value
    end
  end

  has_many :enrollments

  # has_many :students, through: :enrollments, foreign_key: :user_id, class_name: 'User'
  has_many :student_programs, through: :enrollments, source: :program

  has_many :teacher_enrollments, foreign_key: :teacher_id, class_name: 'Enrollment'

  # has_many :teachers, through: :teacher_enrollments, foreign_key: :teacher_id, class_name: 'User'
  has_many :teacher_programs, through: :teacher_enrollments, source: :program

  validate :role_consistency_with_programs, on: :update

  def favorite_teachers
    enrollments.where(favorite: true).map(&:teacher)
  end

  def classmates
    User.joins(:enrollments).where(enrollments: {program_id: student_programs.pluck(:id)}).where.not(id: id).distinct
  end

  private
    def role_consistency_with_programs
      if teacher? && teacher_programs.present?
        errors.add(:base, "Kind can not be student because is teaching in at least one program")
      elsif student? && student_programs.present?
        errors.add(:base, "Kind can not be teacher because is studying in at least one program")
      elsif student_teacher? && teacher_programs.present? && student_programs.present?
        errors.add(:base, "Kind can not be student/teacher because is teaching/studying in at least one program")
      end
    end
end
