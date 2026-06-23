"""add assessment summaries table

Revision ID: f9a7c3d2e1b4
Revises: e4b2c1a9d8f0
Create Date: 2026-06-23 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'f9a7c3d2e1b4'
down_revision = 'e4b2c1a9d8f0'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'assessment_summaries',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('user_id', sa.String(length=36), nullable=False),
        sa.Column('probability', sa.Float(), nullable=False),
        sa.Column('risk_tier', sa.String(length=20), nullable=False),
        sa.Column('age_group', sa.String(length=40), nullable=False),
        sa.Column('feedback_outcome', sa.String(length=20), nullable=True),
        sa.Column('created_at', sa.Float(), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
    )


def downgrade():
    op.drop_table('assessment_summaries')
