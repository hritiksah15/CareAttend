"""add outreach actions table

Revision ID: a3c9d7e5f1b2
Revises: f9a7c3d2e1b4
Create Date: 2026-06-23 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'a3c9d7e5f1b2'
down_revision = 'f9a7c3d2e1b4'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'outreach_actions',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('user_id', sa.String(length=36), nullable=False),
        sa.Column('notification_id', sa.String(length=36), nullable=True),
        sa.Column('patient_id', sa.String(length=80), nullable=False),
        sa.Column('action_type', sa.String(length=40), nullable=False),
        sa.Column('risk_tier', sa.String(length=20), nullable=True),
        sa.Column('appointment_date', sa.String(length=30), nullable=True),
        sa.Column('status', sa.String(length=20), nullable=False),
        sa.Column('outcome', sa.String(length=40), nullable=True),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_by', sa.String(length=80), nullable=False),
        sa.Column('created_at', sa.Float(), nullable=False),
        sa.Column('completed_at', sa.Float(), nullable=True),
        sa.ForeignKeyConstraint(['notification_id'], ['notifications.id'], ),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
    )


def downgrade():
    op.drop_table('outreach_actions')
