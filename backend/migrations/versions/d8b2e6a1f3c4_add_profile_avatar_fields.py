"""add profile avatar and identity fields

Revision ID: d8b2e6a1f3c4
Revises: c7a1f4e9d2b0
Create Date: 2026-06-20 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'd8b2e6a1f3c4'
down_revision = 'c7a1f4e9d2b0'
branch_labels = None
depends_on = None


def upgrade():
    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.add_column(sa.Column('avatar', sa.Text(), nullable=True))
        batch_op.add_column(sa.Column('job_title', sa.String(length=100), nullable=True))
        batch_op.add_column(sa.Column('department', sa.String(length=100), nullable=True))
        batch_op.add_column(sa.Column('bio', sa.String(length=300), nullable=True))
        batch_op.add_column(sa.Column('phone', sa.String(length=30), nullable=True))
        batch_op.add_column(sa.Column('pronouns', sa.String(length=30), nullable=True))


def downgrade():
    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.drop_column('pronouns')
        batch_op.drop_column('phone')
        batch_op.drop_column('bio')
        batch_op.drop_column('department')
        batch_op.drop_column('job_title')
        batch_op.drop_column('avatar')
