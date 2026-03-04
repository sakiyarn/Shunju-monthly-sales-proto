# frozen_string_literal: true

require "test_helper"

class DirectedExpensesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @active_project_a = Project.create!(name: "進行案件A", is_active: true)
    @active_project_b = Project.create!(name: "進行案件B", is_active: true)
    @closed_project = Project.create!(name: "終了案件", is_active: false)
  end

  test "create directed expense with active projects" do
    assert_difference("DirectedExpense.count", 1) do
      assert_difference("DirectedExpenseAssignment.count", 2) do
        post directed_expenses_path, params: {
          directed_expense: {
            work_month: "2026-01",
            description: "AWS利用料",
            amount: 120_000,
            project_ids: [@active_project_a.id, @active_project_b.id]
          }
        }
      end
    end

    assert_redirected_to master_path
    expense = DirectedExpense.order(:id).last
    assert_equal Date.new(2026, 1, 1), expense.work_month
    assert_equal "AWS利用料", expense.description
    assert_equal 120_000, expense.amount.to_i
    assert_equal [@active_project_a.id, @active_project_b.id].sort, expense.directed_expense_assignments.pluck(:project_id).sort
  end

  test "create rejects empty project_ids" do
    assert_no_difference("DirectedExpense.count") do
      post directed_expenses_path, params: {
        directed_expense: {
          work_month: "2026-01",
          description: "AWS利用料",
          amount: 120_000,
          project_ids: []
        }
      }
    end

    assert_redirected_to master_path
  end

  test "create rejects duplicated project_ids" do
    assert_no_difference("DirectedExpense.count") do
      post directed_expenses_path, params: {
        directed_expense: {
          work_month: "2026-01",
          description: "AWS利用料",
          amount: 120_000,
          project_ids: [@active_project_a.id, @active_project_a.id]
        }
      }
    end

    assert_redirected_to master_path
  end

  test "create rejects closed project_ids" do
    assert_no_difference("DirectedExpense.count") do
      post directed_expenses_path, params: {
        directed_expense: {
          work_month: "2026-01",
          description: "AWS利用料",
          amount: 120_000,
          project_ids: [@closed_project.id]
        }
      }
    end

    assert_redirected_to master_path
  end

  test "create rejects missing project_ids" do
    assert_no_difference("DirectedExpense.count") do
      post directed_expenses_path, params: {
        directed_expense: {
          work_month: "2026-01",
          description: "AWS利用料",
          amount: 120_000,
          project_ids: [-1]
        }
      }
    end

    assert_redirected_to master_path
  end

  test "create rejects invalid work_month" do
    assert_no_difference("DirectedExpense.count") do
      post directed_expenses_path, params: {
        directed_expense: {
          work_month: "2026-13",
          description: "AWS利用料",
          amount: 120_000,
          project_ids: [@active_project_a.id]
        }
      }
    end

    assert_redirected_to master_path
  end

  test "create rejects invalid amount" do
    assert_no_difference("DirectedExpense.count") do
      post directed_expenses_path, params: {
        directed_expense: {
          work_month: "2026-01",
          description: "AWS利用料",
          amount: "1200.5",
          project_ids: [@active_project_a.id]
        }
      }
    end

    assert_redirected_to master_path
  end

  test "update replaces active assignments and keeps closed assignments" do
    expense = DirectedExpense.create!(work_month: Date.new(2026, 1, 1), description: "初期経費", amount: 30_000)
    DirectedExpenseAssignment.create!(directed_expense: expense, project: @active_project_a)
    DirectedExpenseAssignment.create!(directed_expense: expense, project: @closed_project)

    patch directed_expense_path(expense), params: {
      directed_expense: {
        work_month: "2026-02",
        description: "修正後経費",
        amount: 88_000,
        project_ids: [@active_project_b.id]
      }
    }

    assert_redirected_to master_path
    assert_equal Date.new(2026, 2, 1), expense.reload.work_month
    assert_equal "修正後経費", expense.description
    assert_equal 88_000, expense.amount.to_i
    assert_equal [@active_project_b.id, @closed_project.id].sort, expense.directed_expense_assignments.pluck(:project_id).sort
  end

  test "update accepts empty active projects when closed assignment exists" do
    expense = DirectedExpense.create!(work_month: Date.new(2026, 1, 1), description: "初期経費", amount: 30_000)
    DirectedExpenseAssignment.create!(directed_expense: expense, project: @closed_project)

    patch directed_expense_path(expense), params: {
      directed_expense: {
        work_month: "2026-03",
        description: "終了案件のみ保持",
        amount: 77_000,
        project_ids: []
      }
    }

    assert_redirected_to master_path
    assert_equal Date.new(2026, 3, 1), expense.reload.work_month
    assert_equal [@closed_project.id], expense.directed_expense_assignments.pluck(:project_id)
  end

  test "update rejects when final assignments become empty" do
    expense = DirectedExpense.create!(work_month: Date.new(2026, 1, 1), description: "初期経費", amount: 30_000)
    DirectedExpenseAssignment.create!(directed_expense: expense, project: @active_project_a)

    patch directed_expense_path(expense), params: {
      directed_expense: {
        work_month: "2026-03",
        description: "案件未選択",
        amount: 77_000,
        project_ids: []
      }
    }

    assert_redirected_to master_path
    assert_equal [@active_project_a.id], expense.reload.directed_expense_assignments.pluck(:project_id)
  end

  test "update missing directed expense returns 404" do
    patch directed_expense_path(-1), params: {
      directed_expense: {
        work_month: "2026-01",
        description: "存在しない経費",
        amount: 10_000,
        project_ids: [@active_project_a.id]
      }
    }

    assert_response :not_found
  end

  test "destroy directed expense" do
    expense = DirectedExpense.create!(work_month: Date.new(2026, 1, 1), description: "削除対象", amount: 12_000)
    DirectedExpenseAssignment.create!(directed_expense: expense, project: @active_project_a)

    assert_difference("DirectedExpense.count", -1) do
      delete directed_expense_path(expense)
    end

    assert_redirected_to master_path
  end

  test "destroy missing directed expense returns 404" do
    delete directed_expense_path(-1)

    assert_response :not_found
  end
end
