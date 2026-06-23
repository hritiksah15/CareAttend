"""add notifications table

Revision ID: e4b2c1a9d8f0
Revises: d8b2e6a1f3c4
Create Date: 2026-06-23 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'e4b2c1a9d8f0'
down_revision = 'd8b2e6a1f3c4'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'notifications',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('user_id', sa.String(length=36), nullable=False),
        sa.Column('patient_id', sa.String(length=80), nullable=False),
        sa.Column('risk_tier', sa.String(length=20), nullable=False),
        sa.Column('appointment_date', sa.String(length=30), nullable=True),
        sa.Column('notify_at', sa.String(length=50), nullable=False),
        sa.Column('status', sa.String(length=20), nullable=False),
        sa.Column('created_by', sa.String(length=80), nullable=False),
        sa.Column('created_at', sa.Float(), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
    )


def downgrade():
    op.drop_table('notifications')
