require 'csv'
class FoodDiariesController < ApplicationController
  before_filter :authenticate_user!
  before_action :set_food_diary, only: [:show, :edit, :update, :destroy, :day, :next_day, :breakdown]

  respond_to :html

  def index
    @food_diaries = FoodDiary.all

    respond_to do |format|
      format.html
      format.csv {send_data generate_totals_csv, :filename => "boden_food_diaries_#{DateTime.now.strftime('%d%m%Y')}.csv"}
      format.xls {send_data generate_totals_csv(col_sep: "\t"), :filename => "boden_food_diaries_#{DateTime.now.strftime('%d%m%Y')}.xls"}
    end
  end

  def show
    @hide_nav = true
    @meals = @food_diary.meals.where(day: @day.to_i)
  end

  def day
    @hide_nav = true
    @day = params[:day]
    @meals = @food_diary.meals.where(day: @day.to_i)
    @default_plates = ['Breakfast', 'Snack', 'Lunch', 'Snack', 'Dinner']
    render :show
  end

  def next_day
    @hide_nav = true
    meals_json = JSON.parse(params[:meals_json])

    Meal.delete_all("food_diary_id = #{@food_diary.id} AND day = #{params[:day].to_i}")

    meals_json.each do |meal_json|
      meal = Meal.new(name: meal_json["name"], day: meal_json["day"], food_diary_id: meal_json["food_diary_id"])
      meal_json["foods"].each do |food_id|
        food = Food.find(food_id)
        meal.foods << food unless food.nil?
        meal.save!
      end
    end

    next_day = params[:day].to_i + 1

    if next_day > 3
      redirect_to food_diary_breakdown_path(@food_diary)
    else
      redirect_to fd_day_path(@food_diary, next_day)
    end
  end

  def search_category
    @category = FoodCategory.find(params[:id])
    render layout: false
  end

  def breakdown
    @participant = @food_diary.participant
    setNutritionalValues(@food_diary)
  end

  def new
    @food_diary = FoodDiary.new
    respond_with(@food_diary)
  end

  def edit
  end

  def create
    @food_diary = FoodDiary.new(food_diary_params)

    participant = Participant.find_by_pid(participant_params[:pid])

    if participant.nil?
      participant = Participant.new(participant_params)
      participant.save!
    end

    @food_diary.participant = participant
    @food_diary.save
    redirect_to "#{food_diary_path(@food_diary)}/1"
  end

  def update
    @food_diary.update(food_diary_params)
    respond_with(@food_diary)
  end

  def destroy
    @food_diary.destroy
    respond_with(@food_diary)
  end

  private
  def set_food_diary
    @food_diary = FoodDiary.find(params[:id])
  end

  def food_diary_params
    params[:food_diary].permit(:visit_number)
  end

  def participant_params
    params[:food_diary][:participant].permit(:pid, :date_of_birth, :gender, :group)
  end

  def generate_totals_csv(options = {})
    sql = '''
      select parts.pid as participant_id, parts.group, parts.gender, parts.date_of_birth, totals.visit_number, totals.fd_date as date ,totals.total_energy,
      totals.total_energy_c,
      totals.total_protein,
      totals.total_total_fat,
      totals.total_saturated_fat,
      totals.total_cholesterol,
      totals.total_carbohydrate,
      totals.total_sugars,
      totals.total_dietary_fibre,
      totals.total_sodium from
      (select s.food_diary_id, s.participant_id, s.visit_number, s.fd_date, SUM(energy) as total_energy,
      ROUND(SUM(energy_c)::numeric, 2) as total_energy_c,
      SUM(protein) as total_protein,
      SUM(total_fat) as total_total_fat,
      SUM(saturated_fat) as total_saturated_fat,
      SUM(cholesterol) as total_cholesterol,
      SUM(carbohydrate) as total_carbohydrate,
      SUM(sugars) as total_sugars,
      SUM(dietary_fibre) as total_dietary_fibre,
      SUM(sodium) as total_sodium from foods as f
      inner join
        (select food_id, fdm.food_diary_id, fdm.visit_number, fdm.participant_id, fdm.fd_date from foods_meals as fm
        right outer join
          (select m.food_diary_id, fd.visit_number, fd.participant_id, m.id as meal_id, fd.created_at as fd_date
          from food_diaries as fd
          inner join meals as m
          on m.food_diary_id=fd.id) as fdm
        on fdm.meal_id = fm.meal_id) as s
      on f.id = s.food_id group by food_diary_id, visit_number, participant_id, fd_date) as totals
      inner join participants as parts on totals.participant_id=parts.id;
    '''
    totals = ActiveRecord::Base.connection.exec_query(sql).to_hash

    CSV.generate(options) do |csv|
      csv << totals[0].keys.map!(&:titleize)
      totals.each do |fd|
        gender = Participant.genders.select{|key, val| key if val == fd['gender'].to_i }.first[0]
        fd['gender'] = gender
        csv << fd.values
      end
    end

  end

  def setNutritionalValues(food_diary)

    day1_meals = Meal.includes(:foods).where(food_diary_id: food_diary.id, day: 1)
    day2_meals = Meal.includes(:foods).where(food_diary_id: food_diary.id, day: 2)
    day3_meals = Meal.includes(:foods).where(food_diary_id: food_diary.id, day: 3)

    @days = [day1_meals, day2_meals, day3_meals]

    sql = """
      Select s.meal_id, SUM(energy) as total_energy,
      ROUND(SUM(energy_c)::numeric, 2) as total_energy_c,
      SUM(protein) as total_protein,
      SUM(total_fat) as total_total_fat,
      SUM(saturated_fat) as total_saturated_fat,
      SUM(cholesterol) as total_cholesterol,
      SUM(carbohydrate) as total_carbohydrate,
      SUM(sugars) as total_sugars,
      SUM(dietary_fibre) as total_dietary_fibre,
      SUM(sodium) as total_sodium
      from foods as f inner join
        (SELECT food_id, meal_id FROM foods_meals where meal_id
          IN (SELECT id from meals where food_diary_id = #{food_diary.id})) as s
      ON f.id=s.food_id GROUP by s.meal_id
    """
    @meal_totals = ActiveRecord::Base.connection.exec_query(sql).to_hash

    @day_totals = []

    @overall_total = {:total_energy => 0,
                      :total_energy_c => 0,
                      :total_protein => 0,
                      :total_total_fat => 0,
                      :total_saturated_fat => 0,
                      :total_cholesterol => 0,
                      :total_carbohydrate => 0,
                      :total_sugars => 0,
                      :total_dietary_fibre => 0,
                      :total_sodium => 0
    }

    @days.each do |day|
      day_total = {:total_energy => 0,
                   :total_energy_c => 0,
                   :total_protein => 0,
                   :total_total_fat => 0,
                   :total_saturated_fat => 0,
                   :total_cholesterol => 0,
                   :total_carbohydrate => 0,
                   :total_sugars => 0,
                   :total_dietary_fibre => 0,
                   :total_sodium => 0
      }
      day.pluck(:id).each do |id|
        meal_total = @meal_totals.select {|m| m["meal_id"] == "#{id}"}.first
        day_total[:total_energy] += meal_total['total_energy'].to_f
        day_total[:total_energy_c] += meal_total['total_energy_c'].to_f
        day_total[:total_protein] += meal_total['total_protein'].to_f
        day_total[:total_total_fat] += meal_total['total_total_fat'].to_f
        day_total[:total_saturated_fat] += meal_total['total_saturated_fat'].to_f
        day_total[:total_cholesterol] += meal_total['total_cholesterol'].to_f
        day_total[:total_carbohydrate] += meal_total['total_carbohydrate'].to_f
        day_total[:total_sugars] += meal_total['total_sugars'].to_f
        day_total[:total_dietary_fibre] += meal_total['total_dietary_fibre'].to_f
        day_total[:total_sodium] += meal_total['total_sodium'].to_f

        @overall_total[:total_energy] += meal_total['total_energy'].to_f
        @overall_total[:total_energy_c] += meal_total['total_energy_c'].to_f
        @overall_total[:total_protein] += meal_total['total_protein'].to_f
        @overall_total[:total_total_fat] += meal_total['total_total_fat'].to_f
        @overall_total[:total_saturated_fat] += meal_total['total_saturated_fat'].to_f
        @overall_total[:total_cholesterol] += meal_total['total_cholesterol'].to_f
        @overall_total[:total_carbohydrate] += meal_total['total_carbohydrate'].to_f
        @overall_total[:total_sugars] += meal_total['total_sugars'].to_f
        @overall_total[:total_dietary_fibre] += meal_total['total_dietary_fibre'].to_f
        @overall_total[:total_sodium] += meal_total['total_sodium'].to_f
      end
      @day_totals.append(day_total)
    end

    @carb_percent = @overall_total[:total_energy] == 0 ? 0:(((@overall_total[:total_carbohydrate]/3) * 16)/(@overall_total[:total_energy]/3) * 100).to_i
    @protein_percent = @overall_total[:total_energy] == 0 ? 0:(((@overall_total[:total_protein]/3) * 16)/(@overall_total[:total_energy]/3) * 100).to_i
    @total_fat_percent = @overall_total[:total_energy] == 0 ? 0:(((@overall_total[:total_total_fat]/3) * 36)/(@overall_total[:total_energy]/3) * 100).to_i
    @sat_fat_percent = @overall_total[:total_energy] == 0 ? 0:(((@overall_total[:total_saturated_fat]/3) * 36)/(@overall_total[:total_energy]/3) * 100).to_i

    @carb_text = 'within'
    @protein_text = 'within'
    @total_fat_text = 'within'
    @sat_fat_text = 'within'

    if @carb_percent > 65
      @carb_text = 'above'
    elsif @carb_percent < 45
      @carb_text = 'below'
    end

    if @protein_percent > 25
      @protein_text = 'above'
    elsif @protein_percent < 15
      @protein_text = 'below'
    end

    if @total_fat_percent > 35
      @total_fat_text = 'above'
    elsif @total_fat_percent < 20
      @total_fat_text = 'below'
    end

    if @sat_fat_percent > 10
      @sat_fat_text = 'above'
    elsif @sat_fat_percent <= 0
      @sat_fat_text = 'below'
    end

  end
end
