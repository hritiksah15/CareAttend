"""add appointments table

Revision ID: b7d4e2c9a6f0
Revises: a3c9d7e5f1b2
Create Date: 2026-06-23 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'b7d4e2c9a6f0'
down_revision = 'a3c9d7e5f1b2'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'appointments',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('user_id', sa.String(length=36), nullable=False),
        sa.Column('patient_id', sa.String(length=80), nullable=False),
        sa.Column('appointment_date', sa.String(length=30), nullable=False),
        sa.Column('appointment_time', sa.String(length=20), nullable=True),
        sa.Column('clinic', sa.String(length=120), nullable=True),
        sa.Column('status', sa.String(length=20), nullable=False),
        sa.Column('probability', sa.Float(), nullable=True),
        sa.Column('risk_tier', sa.String(length=20), nullable=True),
        sa.Column('age_group', sa.String(length=40), nullable=True),
        sa.Column('created_at', sa.Float(), nullable=False),
        sa.Column('updated_at', sa.Float(), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
    )


def downgrade():
    op.drop_table('appointments')
