-- Create users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create expense_source_types table
CREATE TABLE expense_source_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create expense_categories table
CREATE TABLE expense_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    icon_name VARCHAR(50), -- For UI display
    color VARCHAR(7), -- Hex color code for UI
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create income_categories table
CREATE TABLE income_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    icon_name VARCHAR(50), -- For UI display
    color VARCHAR(7), -- Hex color code for UI
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Insert default expense categories
INSERT INTO expense_categories (name, description, icon_name, color) VALUES
    ('FOOD', 'Food and beverages', 'food', '#FF5733'),
    ('TRANSPORT', 'Transportation and travel', 'car', '#33FF57'),
    ('HOUSING', 'Housing and utilities', 'home', '#3357FF'),
    ('ENTERTAINMENT', 'Entertainment and leisure', 'movie', '#F333FF'),
    ('SHOPPING', 'Shopping and retail', 'shopping', '#FF33F3'),
    ('HEALTHCARE', 'Healthcare and medical', 'medical', '#33FFF3'),
    ('EDUCATION', 'Education and learning', 'school', '#F3FF33'),
    ('PERSONAL_CARE', 'Personal care and beauty', 'spa', '#FF3333'),
    ('SUBSCRIPTIONS', 'Subscriptions and memberships', 'subscription', '#33FF33'),
    ('SAVINGS', 'Savings and investments', 'savings', '#3333FF'),
    ('DEBT_PAYMENT', 'Debt payments and loans', 'debt', '#FF33FF'),
    ('GIFTS', 'Gifts and donations', 'gift', '#33FFFF'),
    ('OTHER', 'Other expenses', 'other', '#808080');

-- Insert default income categories
INSERT INTO income_categories (name, description, icon_name, color) VALUES
    ('SALARY', 'Regular salary or wages', 'work', '#4CAF50'),
    ('FREELANCE', 'Freelance or contract work', 'freelance', '#2196F3'),
    ('INVESTMENT', 'Investment returns and dividends', 'investment', '#FFC107'),
    ('BUSINESS', 'Business income', 'business', '#9C27B0'),
    ('RENTAL', 'Rental property income', 'home', '#FF9800'),
    ('GIFT', 'Gifts and donations received', 'gift', '#E91E63'),
    ('REFUND', 'Refunds and reimbursements', 'refund', '#00BCD4'),
    ('INTEREST', 'Interest earned', 'interest', '#8BC34A'),
    ('SIDE_HUSTLE', 'Side hustle income', 'side-hustle', '#FF5722'),
    ('GOVERNMENT', 'Government benefits and assistance', 'government', '#607D8B'),
    ('OTHER', 'Other income sources', 'other', '#9E9E9E');

-- Insert default expense source types
INSERT INTO expense_source_types (name, description) VALUES
    ('CREDIT_CARD', 'Credit card payment source'),
    ('DEBIT_CARD', 'Debit card payment source'),
    ('CASH', 'Physical cash'),
    ('BANK_TRANSFER', 'Direct bank transfer'),
    ('DIGITAL_WALLET', 'Digital wallet (PayPal, Venmo, etc.)');

-- Create expense_sources table
CREATE TABLE expense_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_id UUID NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
    type_id UUID NOT NULL REFERENCES expense_source_types(id),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    currency VARCHAR(3) NOT NULL, -- Currency for this expense source
    -- Credit card specific fields
    credit_limit DECIMAL(15,2),
    initial_spent_balance DECIMAL(15,2) DEFAULT 0, -- Initial balance when card is added
    interest_rate DECIMAL(5,2),
    billing_cycle_start_day INTEGER CHECK (billing_cycle_start_day BETWEEN 1 AND 31),
    billing_cycle_end_day INTEGER CHECK (billing_cycle_end_day BETWEEN 1 AND 31),
    payment_due_interval INTEGER CHECK (payment_due_interval > 0), -- Number of days after billing_cycle_start_day
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_billing_cycle CHECK (
        (type_id != (SELECT id FROM expense_source_types WHERE name = 'CREDIT_CARD')) OR
        (billing_cycle_start_day IS NOT NULL AND 
         billing_cycle_end_day IS NOT NULL AND 
         payment_due_interval IS NOT NULL)
    )
);

-- Create credit_limit_history table
CREATE TABLE credit_limit_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expense_source_id UUID NOT NULL REFERENCES expense_sources(id) ON DELETE CASCADE,
    credit_limit DECIMAL(15,2) NOT NULL,
    effective_date TIMESTAMP WITH TIME ZONE NOT NULL,
    reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create wallets table
CREATE TABLE wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    balance DECIMAL(15,2) NOT NULL DEFAULT 0,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create expenses table
CREATE TABLE expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    amount DECIMAL(15,2) NOT NULL,
    description TEXT NOT NULL,
    date TIMESTAMP WITH TIME ZONE NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('RECURRING', 'NON_RECURRING')),
    category_id UUID NOT NULL REFERENCES expense_categories(id),
    currency VARCHAR(3) NOT NULL, -- Currency of the expense
    exchange_rate DECIMAL(15,6), -- Exchange rate to wallet's base currency at time of expense
    expense_source_id UUID NOT NULL REFERENCES expense_sources(id) ON DELETE RESTRICT,
    wallet_id UUID NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create credit_card_payments table
CREATE TABLE credit_card_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expense_source_id UUID NOT NULL REFERENCES expense_sources(id) ON DELETE CASCADE,
    amount DECIMAL(15,2) NOT NULL,
    payment_date TIMESTAMP WITH TIME ZONE NOT NULL,
    due_date TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('PENDING', 'PAID', 'LATE', 'MISSED')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create incomes table
CREATE TABLE incomes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    amount DECIMAL(15,2) NOT NULL,
    description TEXT NOT NULL,
    date TIMESTAMP WITH TIME ZONE NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('RECURRING', 'NON_RECURRING')),
    category_id UUID NOT NULL REFERENCES income_categories(id),
    currency VARCHAR(3) NOT NULL, -- Currency of the income
    exchange_rate DECIMAL(15,6), -- Exchange rate to wallet's base currency at time of income
    expense_source_id UUID NOT NULL REFERENCES expense_sources(id) ON DELETE RESTRICT,
    wallet_id UUID NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create budgets table
CREATE TABLE budgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    wallet_id UUID NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES expense_categories(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    period_start_date DATE NOT NULL,
    period_end_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_amount CHECK (amount > 0),
    CONSTRAINT valid_period CHECK (period_end_date > period_start_date)
);

-- Create recurring transactions table
CREATE TABLE recurring_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    wallet_id UUID NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
    expense_source_id UUID REFERENCES expense_sources(id) ON DELETE SET NULL,
    amount DECIMAL(10,2) NOT NULL,
    description TEXT NOT NULL,
    frequency VARCHAR(20) NOT NULL, -- DAILY, WEEKLY, MONTHLY, YEARLY
    start_date DATE NOT NULL,
    end_date DATE,
    last_occurrence_date DATE,
    next_occurrence_date DATE,
    category_id UUID REFERENCES expense_categories(id) ON DELETE SET NULL,
    type VARCHAR(20) NOT NULL, -- EXPENSE, INCOME
    currency VARCHAR(3) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_amount CHECK (amount > 0),
    CONSTRAINT valid_frequency CHECK (frequency IN ('DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY')),
    CONSTRAINT valid_type CHECK (type IN ('EXPENSE', 'INCOME'))
);

-- Create tags table
CREATE TABLE tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    wallet_id UUID NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    color VARCHAR(7) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(wallet_id, name)
);

-- Create transaction tags junction table
CREATE TABLE transaction_tags (
    transaction_id UUID NOT NULL,
    tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    transaction_type VARCHAR(20) NOT NULL, -- EXPENSE, INCOME
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (transaction_id, tag_id, transaction_type),
    CONSTRAINT valid_transaction_type CHECK (transaction_type IN ('EXPENSE', 'INCOME'))
);

-- Create user preferences table
CREATE TABLE user_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    default_currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    language VARCHAR(10) NOT NULL DEFAULT 'en',
    timezone VARCHAR(50) NOT NULL DEFAULT 'UTC',
    notification_enabled BOOLEAN NOT NULL DEFAULT true,
    email_notifications BOOLEAN NOT NULL DEFAULT true,
    push_notifications BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

-- Create notifications table
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL, -- PAYMENT_DUE, BUDGET_LIMIT, etc.
    title VARCHAR(100) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create audit logs table
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    action VARCHAR(50) NOT NULL, -- CREATE, UPDATE, DELETE
    entity_type VARCHAR(50) NOT NULL, -- EXPENSE, INCOME, WALLET, etc.
    entity_id UUID NOT NULL,
    old_value JSONB,
    new_value JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_wallets_user_id ON wallets(user_id);
CREATE INDEX idx_expense_sources_wallet_id ON expense_sources(wallet_id);
CREATE INDEX idx_expense_sources_type_id ON expense_sources(type_id);
CREATE INDEX idx_expenses_wallet_id ON expenses(wallet_id);
CREATE INDEX idx_expenses_expense_source_id ON expenses(expense_source_id);
CREATE INDEX idx_expenses_category_id ON expenses(category_id);
CREATE INDEX idx_incomes_wallet_id ON incomes(wallet_id);
CREATE INDEX idx_incomes_expense_source_id ON incomes(expense_source_id);
CREATE INDEX idx_incomes_category_id ON incomes(category_id);
CREATE INDEX idx_expenses_date ON expenses(date);
CREATE INDEX idx_incomes_date ON incomes(date);
CREATE INDEX idx_credit_card_payments_expense_source_id ON credit_card_payments(expense_source_id);
CREATE INDEX idx_credit_card_payments_due_date ON credit_card_payments(due_date);
CREATE INDEX idx_credit_limit_history_expense_source_id ON credit_limit_history(expense_source_id);
CREATE INDEX idx_credit_limit_history_effective_date ON credit_limit_history(effective_date);
CREATE INDEX idx_budgets_wallet_id ON budgets(wallet_id);
CREATE INDEX idx_budgets_category_id ON budgets(category_id);
CREATE INDEX idx_recurring_transactions_wallet_id ON recurring_transactions(wallet_id);
CREATE INDEX idx_recurring_transactions_next_occurrence_date ON recurring_transactions(next_occurrence_date);
CREATE INDEX idx_tags_wallet_id ON tags(wallet_id);
CREATE INDEX idx_transaction_tags_transaction_id ON transaction_tags(transaction_id);
CREATE INDEX idx_transaction_tags_tag_id ON transaction_tags(tag_id);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_entity_type ON audit_logs(entity_type);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_wallets_updated_at
    BEFORE UPDATE ON wallets
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_expense_sources_updated_at
    BEFORE UPDATE ON expense_sources
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_expenses_updated_at
    BEFORE UPDATE ON expenses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_incomes_updated_at
    BEFORE UPDATE ON incomes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_credit_card_payments_updated_at
    BEFORE UPDATE ON credit_card_payments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_credit_limit_history_updated_at
    BEFORE UPDATE ON credit_limit_history
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_expense_categories_updated_at
    BEFORE UPDATE ON expense_categories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_income_categories_updated_at
    BEFORE UPDATE ON income_categories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_budgets_updated_at
    BEFORE UPDATE ON budgets
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_recurring_transactions_updated_at
    BEFORE UPDATE ON recurring_transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_tags_updated_at
    BEFORE UPDATE ON tags
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_user_preferences_updated_at
    BEFORE UPDATE ON user_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_notifications_updated_at
    BEFORE UPDATE ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create shared wallets table
CREATE TABLE shared_wallets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create shared wallet members table
CREATE TABLE shared_wallet_members (
    shared_wallet_id UUID NOT NULL REFERENCES shared_wallets(id) ON DELETE CASCADE,
    wallet_id UUID NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL, -- OWNER, ADMIN, MEMBER
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (shared_wallet_id, wallet_id),
    CONSTRAINT valid_role CHECK (role IN ('OWNER', 'ADMIN', 'MEMBER'))
);

-- Modify budgets table to support both individual and shared wallets
ALTER TABLE budgets DROP CONSTRAINT budgets_wallet_id_fkey;
ALTER TABLE budgets ADD COLUMN shared_wallet_id UUID REFERENCES shared_wallets(id) ON DELETE CASCADE;
ALTER TABLE budgets ADD CONSTRAINT budgets_wallet_or_shared_wallet CHECK (
    (wallet_id IS NOT NULL AND shared_wallet_id IS NULL) OR
    (wallet_id IS NULL AND shared_wallet_id IS NOT NULL)
);

-- Create budget allocations table for shared wallets
CREATE TABLE budget_allocations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    budget_id UUID NOT NULL REFERENCES budgets(id) ON DELETE CASCADE,
    wallet_id UUID NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_amount CHECK (amount > 0)
);

-- Create budget tracking table
CREATE TABLE budget_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    budget_id UUID NOT NULL REFERENCES budgets(id) ON DELETE CASCADE,
    expense_id UUID NOT NULL REFERENCES expenses(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_amount CHECK (amount > 0)
);

-- Add indexes for better query performance
CREATE INDEX idx_shared_wallet_members_shared_wallet_id ON shared_wallet_members(shared_wallet_id);
CREATE INDEX idx_shared_wallet_members_wallet_id ON shared_wallet_members(wallet_id);
CREATE INDEX idx_budgets_shared_wallet_id ON budgets(shared_wallet_id);
CREATE INDEX idx_budget_allocations_budget_id ON budget_allocations(budget_id);
CREATE INDEX idx_budget_allocations_wallet_id ON budget_allocations(wallet_id);
CREATE INDEX idx_budget_tracking_budget_id ON budget_tracking(budget_id);
CREATE INDEX idx_budget_tracking_expense_id ON budget_tracking(expense_id);

-- Add triggers for updated_at
CREATE TRIGGER set_shared_wallets_updated_at
    BEFORE UPDATE ON shared_wallets
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_shared_wallet_members_updated_at
    BEFORE UPDATE ON shared_wallet_members
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_budget_allocations_updated_at
    BEFORE UPDATE ON budget_allocations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column(); 