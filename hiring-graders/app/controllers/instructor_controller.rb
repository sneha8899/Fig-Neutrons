class InstructorController < ApplicationController
  def create
    error = false
    @existingStudent = Student.find_by(email: params[:email])
    @existingAdmin = Admin.find_by(email: params[:email])
    if @existingStudent != nil || @existingAdmin != nil
      error = true
    end
    if !error
      @instructor = Instructor.new(first_name: params[:fName], last_name: params[:lName], email: params[:email],
        password: params[:password], password_confirmation: params[:confirmPassword])
      if @instructor.save
        log_in @instructor, 'instructor'
        redirect_to :action => 'profile'
      else
        flash[:danger] = @instructor.errors.full_messages
        redirect_to '/user/signup'
      end
    else
      flash[:danger] = "This email is tied to an existing account. Please log in below."
      redirect_to '/user/login'
    end

  end
  
  def login
    instructor = Instructor.find_by(email: params[:email].downcase)
    if instructor && instructor.authenticate(params[:password])
      log_in instructor, 'instructor'
      redirect_to '/instructor/profile'
    else
      flash[:danger] = "Invalid email/password combination"
      redirect_to '/user/login'
    end
  end

  def recommendation
  end

  def create_recommendation
    @recommend = Recommendation.new(recommendation: params[:recText], student_id: Student.find_by(email: params[:email]).id,
                                    course_number: params[:recCourse], instructor_id: session[:user_id])

    if @recommend.save
      flash[:success] = "Your recommendation was saved successfully!"
      redirect_to '/instructor/profile'
    else
      flash[:danger] = @recommend.errors.full_messages
      redirect_to '/instructor/profile'
    end
  end

  def edit_recommendation
    @recommendations = Recommendation.find_by(instructor_id: session[:user_id])
  end

  def profile
    @instructor = Instructor.find_by id: session[:user_id]
    if !@instructor.nil?
      @instructorName = "#{@instructor.first_name} #{@instructor.last_name}"
    else
      redirect_to '/user/login'
    end
  end



end
