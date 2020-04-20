class StudentController < ApplicationController
  def create
    @student = Student.new(first_name: params[:fName],
                           last_name: params[:lName],
                           email: params[:email],
                           phone: params[:phone],
                           password: params[:password],
                           password_confirmation: params[:confirmPassword])
    if @student.save
      log_in @student, 'student'
      redirect_to :action => 'profile'
    else
      flash[:danger] = @student.errors.full_messages
      redirect_to '/user/signup'
    end

  end
  
  def login
    student = Student.find_by(email: params[:email].downcase)
    if student && student.authenticate(params[:password])
      log_in student, 'student'
      redirect_to '/student/profile'
    else
      flash[:danger] = "Invalid email/password combination"
      redirect_to '/user/login'
    end

  end

  def convert_letter_grades_to_gpa(grade)
    if grade == 'A' then return 93 end
    if grade == 'A-' then return 90 end
    if grade == 'B+' then return 87 end
    if grade == 'B' then return 83 end
    if grade == 'B-' then return 80 end
    if grade == 'C+' then return 77 end
    if grade == 'C' then return 73 end
    if grade == 'C-' then return 70 end
    if grade == 'D+' then return 67 end
    if grade == 'D' then return 60 end
    if grade == 'E' then return 0 end
    return nil
  end

  def convert_number_to_letter_grade(grade)
    if grade == 93 then return 'A' end
    if grade == 90 then return 'A-' end
    if grade == 87 then return 'B+' end
    if grade == 83 then return 'B' end
    if grade == 80 then return 'B-' end
    if grade == 77 then return 'C+' end
    if grade == 73 then return 'C' end
    if grade == 70 then return 'C-' end
    if grade == 67 then return 'D' end
  end

  def application
    @student = Student.find_by id: session[:user_id]
    @grades = Array.new()
    @foundInterestedEntry = false;
    if !@student.nil?
      @studentName = "#{@student.first_name} #{@student.last_name}"
      @studentGrades = Transcript.where student_id: @student.id
      @studentGrades.each_with_index do |transcript, index|
        @grades[index] = convert_number_to_letter_grade(transcript.grade)
      end
    end
    @interestedCourses = Interested.where student_id: @student.id

    error = false;
    if request.post? 
      index = 1
      gradeString = "grade" + index.to_s
      courseString = "courseNum" + index.to_s
      interestedString = "gradeInterest" + index.to_s
      while params[gradeString] != nil

        # Check for errors on input form:
        # incorrect course number entered
        error = true if !params[courseString].match(/^\d{4}/)

        # incorrect grade entered
        error = true if convert_letter_grades_to_gpa(params[gradeString].upcase) == nil

        # missing values for course num or grade
        if params[gradeString].length == 0 || params[courseString].length == 0
          error = true; 

          # if it's the last row of input fields then empty fields are okay
          index = index + 1
          gradeString = "grade" + index.to_s
          if !params[gradeString]
            error = false;
            index = index - 1
            gradeString = "grade" + index.to_s
          end
        end
        break if error

        # Look up interest and transcript information of student
        gradeInterest = Interested.find_by(student_id: @student.id, course: params[courseString])
        transcript = Transcript.find_by(student_id: @student.id, course_id: params[courseString])

        # If the request to grade box is no longer checked and was previously checked, destroy the record 
        if gradeInterest != nil && !params[interestedString]
          gradeInterest.destroy
        elsif !gradeInterest && params[interestedString]
          # Create a new record for interest if there is not an existing record and the student has selected the checkbox
          gradeInterest = Interested.new(student_id: @student.id, department: "CSE", course: params[courseString])
          gradeInterest.save
        end

        # If the student had an existing grade entered for that course, update the grade
        if transcript != nil
          transcript.grade = convert_letter_grades_to_gpa(params[gradeString].upcase)
          transcript.updated_at = Time.new
        else
          # Otherwise create a new record
          transcript = Transcript.new(
              grade: convert_letter_grades_to_gpa(params[gradeString].upcase),
              created_at: Time.new,
              updated_at: Time.new,
              student_id: @student.id,
              course_id: params[courseString])
        end

        # Only save if there is information entered in the course num and grade fields
        transcript.save unless params[courseString].length == 0 || params[gradeString].length == 0

        # Update the name of the input row to check
        index = index + 1
        gradeString = "grade" + index.to_s
        courseString = "courseNum" + index.to_s
        interestedString = "gradeInterest" + index.to_s
      end

      if error 
        flash[:danger] = "Please enter a valid course number/grade"
      end

      redirect_to '/student/application'
    end

  end

  def availability
    Availability.where(student_id: session[:user_id]).destroy_all
    if params[:"0"]
      params[:"0"].each do |item|
        Availability.create(student_id: session[:user_id], day: "M", hour: item )
      end
    end
    if params[:"1"]
      params[:"1"].each do |item|
        Availability.create(student_id: session[:user_id], day: "T", hour: item )
      end
    end
    if params[:"2"]
      params[:"2"].each do |item|
        Availability.create(student_id: session[:user_id], day: "W", hour: item )
      end
    end
    if params[:"3"]
      params[:"3"].each do |item|
        Availability.create(student_id: session[:user_id], day: "R", hour: item )
      end
    end
    if params[:"4"]
      params[:"4"].each do |item|
        Availability.create(student_id: session[:user_id], day: "F", hour: item )
      end
    end
    redirect_to '/student/profile'
  end
  

  def profile
    @student = Student.find_by id: session[:user_id]
    @grades = Array.new()

    if !@student.nil?
      @studentName = "#{@student.first_name} #{@student.last_name}"
      @studentGrades = Transcript.where student_id: @student.id
      @studentGrades.each_with_index do |transcript, index|
        @grades[index] = convert_number_to_letter_grade(transcript.grade)
      end
    end
  end


end