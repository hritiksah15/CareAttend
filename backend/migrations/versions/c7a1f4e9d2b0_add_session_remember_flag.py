"""add session remember flag

Revision ID: c7a1f4e9d2b0
Revises: bb5c1bb3bb30
Create Date: 2026-06-17 13:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'c7a1f4e9d2b0'
down_revision = 'bb5c1bb3bb30'
branch_labels = None
depends_on = None


def upgrade():
    with op.batch_alter_table('sessions', schema=None) as batch_op:
        batch_op.add_column(sa.Column('remember', sa.Boolean(), nullable=False, server_default=sa.text('false')))


def downgrade():
    with op.batch_alter_table('sessions', schema=None) as batch_op:
        batch_op.drop_column('remember')
